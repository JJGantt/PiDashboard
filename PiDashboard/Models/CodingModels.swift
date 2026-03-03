import Foundation

struct TerminalMessage: Identifiable {
    let id = UUID()
    let role: Role
    var content: String
    let timestamp: Date

    enum Role {
        case user, assistant
    }
}

struct TerminalSession {
    var messages: [TerminalMessage] = []
    var isStreaming = false
    var currentResponse = ""
    var label: String = ""
    var sessionId: String?
}

struct StreamEvent: Decodable {
    let type: String      // "delta", "done", "error", "tool"
    let text: String?
    let message: String?
    let name: String?     // tool name for "tool" events
}

struct SessionSummary: Identifiable, Decodable {
    var id: String { sessionId }
    let sessionId: String
    let summary: String
    let endTime: Double
    let entryCount: Int

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case summary
        case endTime = "end_time"
        case entryCount = "entry_count"
    }

    var timeAgo: String {
        let interval = Date.now.timeIntervalSince(Date(timeIntervalSince1970: endTime))
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }
}

struct SessionSummariesResponse: Decodable {
    let sessions: [SessionSummary]
}

struct SessionHistoryMessage: Decodable {
    let role: String
    let content: String
}

struct SessionHistoryResponse: Decodable {
    let messages: [SessionHistoryMessage]
}

