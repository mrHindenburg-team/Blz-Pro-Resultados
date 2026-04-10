import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser { Spacer(minLength: 48) }

            if !message.isUser {
                ZStack {
                    Circle()
                        .fill(LinearGradient.blazeFire)
                        .frame(width: 28, height: 28)
                    Text("🔥")
                        .font(.system(size: 14))
                }
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.callout)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(message.isUser ? Color.blazeRed : Color.blazeCard)
                    .clipShape(.rect(cornerRadius: 18))
                    .shadow(color: message.isUser ? .blazeRed.opacity(0.4) : .clear, radius: 8)

                Text(message.timestamp, format: .dateTime.hour().minute())
                    .font(.caption2)
                    .foregroundStyle(Color.blazeSubtext)
            }

            if !message.isUser { Spacer(minLength: 48) }
        }
    }
}
