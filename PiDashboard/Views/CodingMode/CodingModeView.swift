import SwiftUI

struct CodingModeView: View {
    @StateObject private var store = CodingSessionStore()
    @StateObject private var voice = VoiceInputManager()
    @FocusState private var focusedArea: FocusArea?

    private enum FocusArea: Hashable {
        case terminal
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                TerminalTabBar(
                    activeIndex: $store.activeTerminal,
                    terminals: store.terminals
                )

                TerminalView(
                    session: store.terminals[store.activeTerminal],
                    isFocused: focusedArea == .terminal
                )
                .frame(maxHeight: .infinity)
                .focusable()
                .focused($focusedArea, equals: .terminal)
                .onPlayPauseCommand {
                    voice.promptForInput()
                }

                CodingStatusBar(
                    isConnected: store.isConnected,
                    activeTerminal: store.activeTerminal,
                    isStreaming: store.terminals[store.activeTerminal].isStreaming
                )
            }
        }
        .onAppear {
            focusedArea = .terminal
        }
        .alert("Send to Terminal \(store.activeTerminal + 1)", isPresented: $voice.showTextInput) {
            TextField("Type or press mic to dictate", text: $voice.textInput)
            Button("Send") {
                let text = voice.textInput.trimmingCharacters(in: .whitespacesAndNewlines)
                voice.textInput = ""
                if !text.isEmpty {
                    Task { await store.sendMessage(text) }
                }
            }
            Button("Cancel", role: .cancel) {
                voice.textInput = ""
            }
        }
    }
}
