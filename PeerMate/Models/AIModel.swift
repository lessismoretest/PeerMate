import Foundation

enum AIModel: String, CaseIterable, Identifiable {
    case geminiFlash = "Gemini 2.0 Flash"
    case deepseek = "DeepSeek"
    
    var id: String { rawValue }
}

struct AIConfig: Codable {
    var selectedModel: String
    var geminiApiKey: String
    var deepseekApiKey: String
} 