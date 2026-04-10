import SwiftUI
import SwiftData

struct AIChatView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: AIChatViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    ChatContentView(viewModel: vm)
                } else {
                    ProgressView()
                        .tint(.blazeRed)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.blazeBackground)
                }
            }
            .navigationTitle("Blaze AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.blazeBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear", action: clearChat)
                        .foregroundStyle(Color.blazeSubtext)
                        .font(.caption)
                }
            }
        }
        .task { viewModel = AIChatViewModel(modelContext: modelContext) }
    }

    private func clearChat() {
        viewModel?.clearHistory()
    }
}

struct ChatContentView: View {
    @Bindable var viewModel: AIChatViewModel

    var body: some View {
        ZStack {
            Color.blazeBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                modelBadge
                messageList
                inputBar
            }
        }
    }

    private var modelBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(viewModel.isFoundationModelsAvailable ? Color.green : Color.blazeSubtext)
                .frame(width: 7, height: 7)
            Text(viewModel.isFoundationModelsAvailable ? "Foundation Models · iOS 26" : "Offline Mode")
                .font(.caption2)
                .foregroundStyle(Color.blazeSubtext)
        }
        .padding(.vertical, 8)
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        MessageBubbleView(message: message)
                            .id(message.persistentModelID)
                    }
                    if viewModel.isLoading {
                        TypingIndicatorView()
                            .id("typing")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
            .onChange(of: viewModel.messages.count) {
                if let last = viewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(last.persistentModelID, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.isLoading) {
                if viewModel.isLoading {
                    withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
                }
            }
        }
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.blazeBorder)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.blazeRed)
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
            }

            HStack(spacing: 10) {
                TextField("Ask about the weather…", text: $viewModel.inputText, axis: .vertical)
                    .font(.callout)
                    .foregroundStyle(.white)
                    .tint(.blazeRed)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.blazeCard)
                    .clipShape(.rect(cornerRadius: 20))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.blazeBorder)
                    }

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? AnyShapeStyle(Color.blazeSubtext)
                                : AnyShapeStyle(LinearGradient.blazeFire)
                        )
                }
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
                .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.messages.count)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.blazeBackground)
        }
    }

    private func sendMessage() {
        Task { await viewModel.sendMessage() }
    }
}

struct TypingIndicatorView: View {
    @State private var phase: Int = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle()
                    .fill(LinearGradient.blazeFire)
                    .frame(width: 28, height: 28)
                Image(systemName: "flame.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }

            HStack(spacing: 5) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.blazeSubtext)
                        .frame(width: 7, height: 7)
                        .scaleEffect(phase == i ? 1.4 : 1.0)
                        .animation(.easeInOut(duration: 0.4).delay(Double(i) * 0.15), value: phase)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.blazeCard)
            .clipShape(.rect(cornerRadius: 18))

            Spacer(minLength: 48)
        }
        .task { await animateDots() }
    }

    private func animateDots() async {
        while !Task.isCancelled {
            for i in 0..<3 {
                phase = i
                try? await Task.sleep(for: .milliseconds(400))
            }
        }
    }
}
