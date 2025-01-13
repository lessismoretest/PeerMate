import Foundation

class AIService {
    static let shared = AIService()
    private init() {}
    
    private let geminiBaseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
    private let deepseekBaseURL = "https://api.deepseek.com/v1/chat/completions"
    
    func generateResponse(for person: Person, userAge: Int, using config: AIConfig) async throws -> String {
        guard !config.geminiApiKey.isEmpty || !config.deepseekApiKey.isEmpty else {
            throw AIError.invalidAPIKey
        }
        
        let prompt = """
        请以第一人称的口吻，描述如果\(person.name)活到今天，看到一个\(userAge)岁的人会说些什么。
        要求：
        1. 基于历史资料，说明\(person.name)在\(userAge)岁时的真实经历，说说今天在干啥（基于史诗，如果没有史实，可以往前往后推一段时间，看看有什么相关事件，推理出当时正在干什么，比如正在复盘xxx或正在准备xxx等
        2. 如果\(person.name)活到今天，会对一个\(userAge)岁的年轻人说些什么
        3. 语气要像\(person.name)本人在说话
        4. 回答要包含具体的历史事件和年份
        5. 字数在300字以内
        """
        
        switch config.selectedModel {
        case AIModel.gemini.rawValue:
            return try await callGeminiAPI(prompt: prompt, apiKey: config.geminiApiKey)
        case AIModel.deepseek.rawValue:
            return try await callDeepseekAPI(prompt: prompt, apiKey: config.deepseekApiKey)
        default:
            throw AIError.unsupportedModel
        }
    }
    
    private func callGeminiAPI(prompt: String, apiKey: String) async throws -> String {
        guard let url = URL(string: "\(geminiBaseURL)?key=\(apiKey)") else {
            throw NetworkError.invalidURL
        }
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 800
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            // 打印错误响应以便调试
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("API Error Response:", errorJson)
            }
            throw NetworkError.apiError("API 错误: \(httpResponse.statusCode)")
        }
        
        // 打印原始响应以便调试
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Raw API Response:", jsonString)
        }
        
        let decoder = JSONDecoder()
        let geminiResponse = try decoder.decode(GeminiResponse.self, from: data)
        
        guard let text = geminiResponse.candidates?.first?.content?.parts?.first?.text else {
            throw NetworkError.invalidData
        }
        
        return text
    }
    
    private func callDeepseekAPI(prompt: String, apiKey: String) async throws -> String {
        guard let url = URL(string: deepseekBaseURL) else {
            throw NetworkError.invalidURL
        }
        
        let requestBody: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 800
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("API Error Response:", errorJson)
            }
            throw NetworkError.apiError("API 错误: \(httpResponse.statusCode)")
        }
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Raw API Response:", jsonString)
        }
        
        let decoder = JSONDecoder()
        let deepseekResponse = try decoder.decode(DeepSeekResponse.self, from: data)
        
        guard let content = deepseekResponse.choices?.first?.message?.content else {
            throw NetworkError.invalidData
        }
        
        return content
    }
}

enum AIError: LocalizedError {
    case unsupportedModel
    case invalidAPIKey
    case networkError
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .unsupportedModel:
            return "不支持的 AI 模型"
        case .invalidAPIKey:
            return "请在设置中填写有效的 API Key"
        case .networkError:
            return "网络错误"
        case .rateLimitExceeded:
            return "API 调用次数超限"
        }
    }
} 