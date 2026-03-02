import SwiftUI

/// Manages text/voice input for coding mode on tvOS.
///
/// The Siri Remote microphone is system-controlled — apps cannot access it
/// via AVAudioEngine. Voice input works through tvOS's built-in dictation:
/// press the mic button on the on-screen keyboard to dictate.
@MainActor
final class VoiceInputManager: ObservableObject {
    @Published var showTextInput = false
    @Published var textInput = ""

    func promptForInput() {
        showTextInput = true
    }
}
