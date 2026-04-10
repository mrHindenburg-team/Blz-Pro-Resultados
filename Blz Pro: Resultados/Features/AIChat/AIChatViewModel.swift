import Foundation
import SwiftData
#if canImport(FoundationModels)
import FoundationModels
#endif

@Observable
@MainActor
final class AIChatViewModel {
    var inputText: String = ""
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var isFoundationModelsAvailable: Bool = false

    private(set) var messages: [ChatMessage] = []
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadMessages()
        checkAvailability()
    }

    func loadMessages() {
        let descriptor = FetchDescriptor<ChatMessage>(
            sortBy: [SortDescriptor(\.timestamp)]
        )
        messages = (try? modelContext.fetch(descriptor)) ?? []
        if messages.isEmpty {
            sendGreeting()
        }
    }

    private func sendGreeting() {
        let greeting = ChatMessage(
            content: "Hey! I'm Blaze AI — your personal Brazil heat monitor. Ask me about temperatures, humidity, heat zones, forecasts, or anything weather-related. How can I help you today?",
            isUser: false
        )
        modelContext.insert(greeting)
        messages.append(greeting)
        try? modelContext.save()
    }

    func sendMessage() async {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let userMsg = ChatMessage(content: trimmed, isUser: true)
        modelContext.insert(userMsg)
        messages.append(userMsg)
        inputText = ""
        isLoading = true
        errorMessage = nil

        do {
            let reply = try await fetchReply(for: trimmed)
            let aiMsg = ChatMessage(content: reply, isUser: false)
            modelContext.insert(aiMsg)
            messages.append(aiMsg)
            try modelContext.save()
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func clearHistory() {
        messages.forEach { modelContext.delete($0) }
        try? modelContext.save()
        messages = []
    }

    private func fetchReply(for text: String) async throws -> String {
        if #available(iOS 26, *) {
            return try await foundationModelsReply(for: text)
        } else {
            return await fallbackReply(for: text)
        }
    }

    private func checkAvailability() {
        if #available(iOS 26, *) {
            Task {
                isFoundationModelsAvailable = await checkFoundationModels()
            }
        }
    }

    @available(iOS 26, *)
    private func checkFoundationModels() async -> Bool {
        let model = SystemLanguageModel.default
        if case .available = model.availability {
            return true
        }
        return false
    }

    @available(iOS 26, *)
    private func foundationModelsReply(for text: String) async throws -> String {
        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            return await fallbackReply(for: text)
        }
        let session = LanguageModelSession(instructions: """
            You are a weather assistant specializing in Brazil's climate, called Blaze AI.
            Reply in English, concisely and helpfully.
            Focus on temperature, humidity, heat zones, forecasts, and solar activity.
            Use no more than 3 sentences per reply.
            """)
        let response = try await session.respond(to: text)
        return response.content
    }

    private func fallbackReply(for text: String) async -> String {
        try? await Task.sleep(for: .milliseconds(600))
        let lower = text.lowercased()
        if lower.contains("temperature") || lower.contains("hot") || lower.contains("heat")
            || lower.contains("temperatura") || lower.contains("quente") || lower.contains("calor") {
            return "🌡️ The hottest zones in Brazil right now are Palmas (38.5°C), Cuiabá (37.8°C), and Fortaleza (36.2°C). The inland Center-West records the most extreme temperatures."
        } else if lower.contains("humidity") || lower.contains("rain") || lower.contains("wet")
            || lower.contains("umidade") || lower.contains("chuva") || lower.contains("húmido") {
            return "💧 The Amazon leads with humidity above 85%. The northeastern coast sits around 72–75%, while the Cerrado is drier at 45–55%."
        } else if lower.contains("map") || lower.contains("zone") || lower.contains("region")
            || lower.contains("mapa") || lower.contains("zona") || lower.contains("região") {
            return "🗺️ The map shows 13 monitored zones. Regions in intense red indicate high solar activity. The North and Northeast lead today's heat index."
        } else if lower.contains("forecast") || lower.contains("tomorrow") || lower.contains("week")
            || lower.contains("previsão") || lower.contains("amanhã") || lower.contains("semana") {
            return "📅 The forecast points to above-average heat in the Northeast and Center-West for the next 5 days. The South and Southeast should see milder temperatures with possible rainfall."
        } else if lower.contains("blaze") || lower.contains("app") || lower.contains("aplicativo") {
            return "🔥 Blaze Results monitors heat zones across Brazil in real time, with Crash-style temperature charts and integrated AI for climate analysis."
        } else {
            return "🌤️ I can help with temperature, humidity, heat zones, weather forecasts, and solar activity analysis in Brazil. What would you like to know?"
        }
    }
}
