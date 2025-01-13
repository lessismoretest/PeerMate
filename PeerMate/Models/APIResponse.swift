import Foundation

// Gemini API 响应模型
struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]?
    let promptFeedback: PromptFeedback?
}

struct GeminiCandidate: Codable {
    let content: GeminiContent?
    let finishReason: String?
    let index: Int?
    let safetyRatings: [SafetyRating]?
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]?
    let role: String?
}

struct GeminiPart: Codable {
    let text: String?
}

struct PromptFeedback: Codable {
    let safetyRatings: [SafetyRating]?
}

struct SafetyRating: Codable {
    let category: String?
    let probability: String?
}

// DeepSeek API 响应模型
struct DeepSeekResponse: Codable {
    let id: String?
    let object: String?
    let created: Int?
    let model: String?
    let choices: [DeepSeekChoice]?
    let usage: Usage?
}

struct DeepSeekChoice: Codable {
    let index: Int?
    let message: DeepSeekMessage?
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index
        case message
        case finishReason = "finish_reason"
    }
}

struct DeepSeekMessage: Codable {
    let role: String?
    let content: String?
}

struct Usage: Codable {
    let promptTokens: Int?
    let completionTokens: Int?
    let totalTokens: Int?
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
} 