import SwiftUI

struct TerminalPanesView: View {
    @ObservedObject var store: CodingSessionStore
    let onExpand: () -> Void
    let onSessionSwitch: (Int) -> Void
    @FocusState private var focusedPane: Int?
    @FocusState private var focusedSessionButton: Int?
    @Namespace private var paneNamespace

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { idx in
                        Button {
                            store.activeTerminal = idx
                            onExpand()
                        } label: {
                            PaneContent(session: store.terminals[idx], isActive: idx == store.activeTerminal)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.black)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            paneStrokeColor(for: idx),
                                            lineWidth: paneStrokeWidth(for: idx)
                                        )
                                )
                        }
                        .buttonStyle(PaneButtonStyle())
                        .focused($focusedPane, equals: idx)
                        .prefersDefaultFocus(idx == store.activeTerminal, in: paneNamespace)
                        .frame(width: paneWidth(for: idx, totalWidth: geo.size.width))
                        .animation(.easeInOut(duration: 0.3), value: store.activeTerminal)
                    }
                }
            }

            // Session buttons — one centered under each pane
            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { idx in
                        Button {
                            onSessionSwitch(idx)
                        } label: {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.system(size: 12))
                                .foregroundStyle(
                                    focusedSessionButton == idx ? .white : .green.opacity(0.4)
                                )
                        }
                        .buttonStyle(SessionSwitchButtonStyle())
                        .focused($focusedSessionButton, equals: idx)
                        .frame(width: paneWidth(for: idx, totalWidth: geo.size.width))
                    }
                }
            }
            .frame(height: 32)
        }
        .focusScope(paneNamespace)
        .onChange(of: focusedPane) { oldValue, newValue in
            if let pane = newValue {
                store.searchBarFocused = false
                // If focus returned from search bar (oldValue == nil) and landed
                // somewhere other than the active terminal, snap back.
                if oldValue == nil && pane != store.activeTerminal {
                    focusedPane = store.activeTerminal
                } else {
                    store.activeTerminal = pane
                }
            } else if focusedSessionButton == nil {
                store.searchBarFocused = true
            }
        }
        .onChange(of: focusedSessionButton) { _, newValue in
            if newValue != nil {
                store.searchBarFocused = false
            }
        }
    }

    // MARK: - Border logic

    private func paneStrokeColor(for idx: Int) -> Color {
        if idx == store.activeTerminal {
            // Active terminal always green
            return focusedPane == idx ? .green : .green.opacity(0.6)
        } else {
            // Inactive: bright if focused, dim otherwise
            return focusedPane == idx ? .green : .gray.opacity(0.15)
        }
    }

    private func paneStrokeWidth(for idx: Int) -> CGFloat {
        if focusedPane == idx { return 3 }
        if idx == store.activeTerminal { return 2 }
        return 1
    }

    private func paneWidth(for index: Int, totalWidth: CGFloat) -> CGFloat {
        let spacing: CGFloat = 4
        let available = totalWidth - spacing
        return index == store.activeTerminal ? available * 0.5 : available * 0.25
    }
}

private struct PaneContent: View {
    let session: TerminalSession
    let isActive: Bool

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(session.messages) { msg in
                    PaneMessage(message: msg, isActive: isActive)
                }

                if session.isStreaming && !session.currentResponse.isEmpty {
                    Text(session.currentResponse)
                        .font(.system(isActive ? .body : .caption, design: .monospaced))
                        .foregroundStyle(.green)
                }

                if session.isStreaming && session.currentResponse.isEmpty {
                    Text("Thinking...")
                        .font(.system(isActive ? .body : .caption, design: .monospaced))
                        .foregroundStyle(.green.opacity(0.5))
                }
            }
            .padding(isActive ? 16 : 8)
        }
        .defaultScrollAnchor(.bottom)
    }
}

private struct PaneMessage: View {
    let message: TerminalMessage
    let isActive: Bool

    var body: some View {
        if message.role == .user {
            Text("> \(message.content)")
                .font(.system(isActive ? .body : .caption, design: .monospaced))
                .foregroundStyle(.white)
        } else {
            Text(message.content)
                .font(.system(isActive ? .body : .caption, design: .monospaced))
                .foregroundStyle(.green)
        }
    }
}

private struct PaneButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

private struct SessionSwitchButtonStyle: ButtonStyle {
    @Environment(\.isFocused) var isFocused

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(isFocused ? Color.green.opacity(0.2) : Color.clear)
            .cornerRadius(4)
    }
}
