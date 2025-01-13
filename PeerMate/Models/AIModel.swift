import Foundation

enum AIModel: String, CaseIterable, Identifiable {
    case gemini = "Gemini"
    case deepseek = "DeepSeek"
    
    var id: String { rawValue }
}

struct AIConfig: Codable {
    var selectedModel: String
    var geminiApiKey: String
    var deepseekApiKey: String
} 