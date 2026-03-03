import SwiftUI

struct SessionPickerView: View {
    @ObservedObject var store: CodingSessionStore
    let terminal: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                Text("Load Session into Terminal \(terminal + 1)")
                    .font(.system(.title3, design: .monospaced))
                    .foregroundStyle(.green)
                    .padding(.bottom, 16)

                if store.sessionSummaries.isEmpty {
                    Text("No sessions found")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.green.opacity(0.5))
                } else {
                    ForEach(store.sessionSummaries) { summary in
                        Button {
                            dismiss()
                            Task { await store.fetchSessionHistory(summary.sessionId, into: terminal) }
                            // TODO: store.attachSession(summary, to: terminal)
                        } label: {
                            SummaryRow(summary: summary)
                        }
                        .buttonStyle(SummaryRowButtonStyle())
                    }
                }
            }
            .padding(40)
        }
        .background(Color.black.ignoresSafeArea())
        .task {
            await store.fetchSessionSummaries()
        }
    }
}

private struct SummaryRow: View {
    let summary: SessionSummary

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(summary.summary)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.green)
                    .lineLimit(3)

                Text("\(summary.entryCount) messages · \(summary.timeAgo)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.green.opacity(0.45))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
    }
}

private struct SummaryRowButtonStyle: ButtonStyle {
    @Environment(\.isFocused) var isFocused

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 1)
                .fill(isFocused ? Color.green : Color.green.opacity(0.15))
                .frame(width: 3)

            configuration.label
        }
        .padding(.horizontal, 8)
        .background(isFocused ? Color.green.opacity(0.08) : Color.clear)
        .cornerRadius(4)
    }
}
