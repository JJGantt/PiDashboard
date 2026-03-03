import Foundation

@MainActor
final class CodingSessionStore: ObservableObject {
    @Published var terminals: [TerminalSession] = [
        .init(label: ""),
        .init(label: ""),
        .init(label: ""),
    ]
    @Published var activeTerminal = 0
    @Published var isConnected = true
    @Published var searchBarFocused = false
    @Published var sessionSummaries: [SessionSummary] = []

    private var streamTask: Task<Void, Never>?
    private static let persistKey = "terminalSessions"

    // MARK: - Persistence

    func restoreSavedSessions() async {
        guard let saved = UserDefaults.standard.array(forKey: Self.persistKey) as? [[String: String]?] else { return }
        for (idx, entry) in saved.prefix(3).enumerated() {
            guard let entry, let sessionId = entry["sessionId"], let label = entry["label"] else { continue }
            terminals[idx].sessionId = sessionId
            terminals[idx].label = label
        }
    }

    private func saveTerminalState() {
        let data: [[String: String]?] = terminals.map { session in
            guard let sessionId = session.sessionId else { return nil }
            return ["sessionId": sessionId, "label": session.label]
        }
        UserDefaults.standard.set(data, forKey: Self.persistKey)
    }

    func sendMessage(_ text: String) async {
        let idx = activeTerminal
        let userMsg = TerminalMessage(role: .user, content: text, timestamp: .now)
        terminals[idx].messages.append(userMsg)
        terminals[idx].isStreaming = true
        terminals[idx].currentResponse = ""

        var accumulated = ""
        var display = ""

        do {
            var body: [String: Any] = ["terminal": idx, "text": text]
            if let sessionId = terminals[idx].sessionId {
                body["session_id"] = sessionId
                body["is_mac"] = true
            }
            let bodyData = try JSONSerialization.data(withJSONObject: body)

            guard let url = await Self.resolveURL(path: PiConstants.codingMessagePath) else {
                terminals[idx].isStreaming = false
                isConnected = false
                appendError(to: idx, message: "Cannot reach Pi")
                return
            }

            isConnected = true
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = bodyData
            request.timeoutInterval = 300 // Long timeout for Claude responses

            let (bytes, response) = try await URLSession.shared.bytes(for: request)

            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                terminals[idx].isStreaming = false
                appendError(to: idx, message: "Server error")
                return
            }

            for try await line in bytes.lines {
                guard !line.isEmpty else { continue }
                guard let data = line.data(using: .utf8),
                      let event = try? JSONDecoder().decode(StreamEvent.self, from: data) else {
                    continue
                }

                switch event.type {
                case "delta":
                    if let text = event.text {
                        accumulated += text
                        display = accumulated
                        terminals[idx].currentResponse = display
                    }
                case "tool":
                    let toolName = event.name ?? "tool"
                    display = accumulated + "\n> Using \(toolName)...\n"
                    terminals[idx].currentResponse = display
                case "error":
                    let errMsg = event.message ?? "Unknown error"
                    accumulated += "\n[Error: \(errMsg)]\n"
                    terminals[idx].currentResponse = accumulated
                case "done":
                    break
                default:
                    break
                }
            }
        } catch {
            if accumulated.isEmpty {
                appendError(to: idx, message: error.localizedDescription)
            }
        }

        // Finalize: move accumulated text into a message
        if !accumulated.isEmpty {
            let msg = TerminalMessage(role: .assistant, content: accumulated, timestamp: .now)
            terminals[idx].messages.append(msg)
        }
        terminals[idx].currentResponse = ""
        terminals[idx].isStreaming = false
    }

    func clearTerminal(_ index: Int) async {
        terminals[index] = TerminalSession(label: "")
        saveTerminalState()

        // Tell the Pi to clear the session
        guard let url = await Self.resolveURL(path: "\(PiConstants.codingClearPath)/\(index)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = PiConstants.requestTimeout
        _ = try? await URLSession.shared.data(for: request)
    }

    // MARK: - Session Discovery

    func fetchSessionSummaries() async {
        guard let url = await Self.resolveURL(path: PiConstants.codingSessionSummariesPath) else {
            isConnected = false
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return }
            let decoded = try JSONDecoder().decode(SessionSummariesResponse.self, from: data)
            sessionSummaries = decoded.sessions
            isConnected = true
        } catch {
            sessionSummaries = []
        }
    }

    func attachSession(_ summary: SessionSummary, to terminal: Int) {
        let label = String(summary.summary.prefix(40)).trimmingCharacters(in: .whitespaces)
        terminals[terminal].label = label
        terminals[terminal].sessionId = summary.sessionId
        terminals[terminal].messages = []
        saveTerminalState()
    }

    func fetchSessionHistory(_ sessionId: String, into terminal: Int) async {
        guard let url = await Self.resolveURL(path: "\(PiConstants.codingHistoryPath)/\(sessionId)") else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = PiConstants.requestTimeout
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              let decoded = try? JSONDecoder().decode(SessionHistoryResponse.self, from: data) else { return }
        terminals[terminal].messages = decoded.messages.map { msg in
            TerminalMessage(role: msg.role == "user" ? .user : .assistant, content: msg.content, timestamp: .now)
        }
    }

    // MARK: - Private

    private func appendError(to idx: Int, message: String) {
        let msg = TerminalMessage(role: .assistant, content: "[Error: \(message)]", timestamp: .now)
        terminals[idx].messages.append(msg)
    }

    /// Try local IP, then Tailscale. Returns first reachable URL.
    private static func resolveURL(path: String) async -> URL? {
        for baseURL in [PiConstants.localBaseURL, PiConstants.tailscaleBaseURL] {
            if let url = URL(string: "\(baseURL)\(path)") {
                // Quick connectivity check for streaming endpoints
                return url
            }
        }
        return nil
    }
}
