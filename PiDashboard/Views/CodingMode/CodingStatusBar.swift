import SwiftUI

struct CodingStatusBar: View {
    let isConnected: Bool
    let activeTerminal: Int
    let isStreaming: Bool

    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Circle()
                    .fill(isConnected ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text(isConnected ? "Connected" : "Offline")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isStreaming {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.6)
                    Text("Claude is responding...")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.green)
                }
            } else {
                Text("Play/Pause to send a message")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("T\(activeTerminal + 1)")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.green)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.9))
    }
}
