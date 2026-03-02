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
                // Tab bar — buttons are natively focusable
                TerminalTabBar(
                    activeIndex: $store.activeTerminal,
                    terminals: store.terminals
                )

                // Terminal content — focusable area for Play/Pause
                TerminalView(
                    session: store.terminals[store.activeTerminal],
                    isFocused: focusedArea == .terminal
                )
                .frame(maxHeight: .infinity)
                .focusable()
                .focused($focusedArea, equals: .terminal)
                .onPlayPauseCommand {
                    handlePlayPause()
                }

                CodingStatusBar(
                    isConnected: store.isConnected,
                    isRecording: voice.isRecording,
                    interimText: voice.interimText,
                    activeTerminal: store.activeTerminal
                )
            }
        }
        .onAppear {
            focusedArea = .terminal
        }
        .alert("Send Message", isPresented: $voice.showTextInput) {
            TextField("Type or dictate...", text: $voice.textInput)
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

    private func handlePlayPause() {
        if voice.isRecording {
            voice.stopRecording()
            Task {
                let text = await voice.transcribeAudio()
                if !text.isEmpty {
                    await store.sendMessage(text)
                }
            }
        } else {
            voice.toggleRecording()
        }
    }
}
