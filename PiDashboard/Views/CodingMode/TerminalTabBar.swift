import SwiftUI

struct TerminalTabBar: View {
    @Binding var activeIndex: Int
    let terminals: [TerminalSession]

    var body: some View {
        HStack(spacing: 24) {
            ForEach(0..<3, id: \.self) { idx in
                TerminalTabButton(
                    index: idx,
                    isActive: idx == activeIndex,
                    hasMessages: !terminals[idx].messages.isEmpty,
                    isStreaming: terminals[idx].isStreaming
                ) {
                    activeIndex = idx
                }
            }
            Spacer()
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.8))
    }
}

private struct TerminalTabButton: View {
    let index: Int
    let isActive: Bool
    let hasMessages: Bool
    let isStreaming: Bool
    let action: () -> Void

    @Environment(\.isFocused) private var isFocused

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Text("Terminal \(index + 1)")
                        .font(.system(.headline, design: .monospaced))
                        .foregroundStyle(isActive ? .green : .gray)

                    if hasMessages {
                        Circle()
                            .fill(isStreaming ? Color.yellow : Color.green)
                            .frame(width: 8, height: 8)
                    }
                }

                Rectangle()
                    .fill(isActive ? Color.green : Color.clear)
                    .frame(height: 2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isFocused ? Color.green.opacity(0.2) : Color.clear)
        )
    }
}
