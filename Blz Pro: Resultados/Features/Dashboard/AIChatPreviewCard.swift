import SwiftUI
import SwiftData

struct AIChatPreviewCard: View {
    let onOpenChat: () -> Void

    @Query(sort: \ChatMessage.timestamp, order: .reverse) private var messages: [ChatMessage]

    private var latestAIMessage: ChatMessage? {
        messages.first { $0.isUser == false }
    }

    var body: some View {
        Button(action: onOpenChat) {
            VStack(alignment: .leading, spacing: 12) {
                // Header row
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient.blazeFire)
                            .frame(width: 32, height: 32)
                        Text("🔥")
                            .font(.system(size: 16))
                    }
                    Text("Blaze AI")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Text("Open")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.blazeSubtext)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(Color.blazeSubtext)
                }

                Divider()
                    .background(Color.blazeBorder)

                if let msg = latestAIMessage {
                    Text(msg.content)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    Text(msg.timestamp, format: .dateTime.hour().minute())
                        .font(.caption2)
                        .foregroundStyle(Color.blazeSubtext)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "bubble.left.fill")
                            .font(.subheadline)
                            .foregroundStyle(Color.blazeSubtext)
                        Text("Ask about Brazil's climate…")
                            .font(.subheadline)
                            .foregroundStyle(Color.blazeSubtext)
                    }
                }
            }
            .padding(16)
            .background(Color.blazeCard)
            .clipShape(.rect(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(LinearGradient.blazeFire, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: latestAIMessage?.timestamp)
    }
}
