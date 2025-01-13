import Foundation

class AIService {
    static let shared = AIService()
    private init() {}
    
    private let geminiFlashBaseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
    private let deepseekBaseURL = "https://api.deepseek.com/v1/chat/completions"
    
    func generateResponse(for person: Person, userAge: Int, using config: AIConfig) async throws -> String {
        guard !config.geminiApiKey.isEmpty || !config.deepseekApiKey.isEmpty else {
            throw AIError.invalidAPIKey
        }
        
        let prompt = Prompt.generateHistoricalComparison(for: person.name, at: userAge)
        
        switch config.selectedModel {
        case AIModel.geminiFlash.rawValue:
            return try await callGeminiAPI(prompt: prompt, apiKey: config.geminiApiKey)
        case AIModel.deepseek.rawValue:
            return try await callDeepseekAPI(prompt: prompt, apiKey: config.deepseekApiKey)
        default:
            throw AIError.unsupportedModel
        }
    }
    
    // 新增方法，获取历史人物列表
    func fetchFamousPersons(using config: AIConfig) async throws -> [String] {
        guard !config.geminiApiKey.isEmpty || !config.deepseekApiKey.isEmpty else {
            throw AIError.invalidAPIKey
        }
        
        let prompt = Prompt.generateFamousPersonsList()
        
        let response: String
        switch config.selectedModel {
        case AIModel.geminiFlash.rawValue:
            response = try await callGeminiAPI(prompt: prompt, apiKey: config.geminiApiKey)
        case AIModel.deepseek.rawValue:
            response = try await callDeepseekAPI(prompt: prompt, apiKey: config.deepseekApiKey)
        default:
            throw AIError.unsupportedModel
        }
        
        // 首先尝试提取JSON字符串，去掉markdown标记
        let jsonStr = extractJsonString(from: response)
        
        // 尝试解析提取出的JSON
        if let data = jsonStr.data(using: .utf8) {
            do {
                let jsonResponse = try JSONDecoder().decode(PersonsResponse.self, from: data)
                return jsonResponse.persons
            } catch {
                print("JSON解析错误: \(error)")
                // 如果JSON解析失败，尝试提取名字列表
                return extractPersonNames(from: response)
            }
        }
        
        throw NetworkError.invalidData
    }
    
    // 从包含markdown的响应中提取JSON字符串
    private func extractJsonString(from text: String) -> String {
        // 移除markdown json代码块标记
        let pattern = "```(?:json)?\\s*(.+?)\\s*```"
        let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators)
        
        if let match = regex?.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            return String(text[range])
        }
        
        // 如果没找到代码块, 直接返回清理后的文本
        return text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // 从纯文本中提取人名列表
    private func extractPersonNames(from text: String) -> [String] {
        // 先尝试简单提取人名（假设是一个包含名字数组的文本）
        let cleanedText = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 尝试匹配JSON中的名字数组
        let namePattern = "\"([^\"]+)\""
        if let regex = try? NSRegularExpression(pattern: namePattern) {
            let matches = regex.matches(in: cleanedText, range: NSRange(cleanedText.startIndex..., in: cleanedText))
            let names = matches.compactMap { match -> String? in
                if let range = Range(match.range(at: 1), in: cleanedText) {
                    return String(cleanedText[range])
                }
                return nil
            }
            
            if !names.isEmpty {
                return names
            }
        }
        
        // 如果正则提取失败，尝试按行分割
        let lines = cleanedText.components(separatedBy: .newlines)
            .compactMap { line -> String? in
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty { return nil }
                
                // 如果行包含常见的列表前缀，去除前缀
                let withoutPrefix = trimmed
                    .replacingOccurrences(of: #"^\d+\.\s*"#, with: "", options: .regularExpression)
                    .replacingOccurrences(of: #"^-\s*"#, with: "", options: .regularExpression)
                    .replacingOccurrences(of: #"^•\s*"#, with: "", options: .regularExpression)
                    .replacingOccurrences(of: #"^"\s*|\s*"$"#, with: "", options: .regularExpression)
                    .replacingOccurrences(of: #"[,\[\]{}]"#, with: "", options: .regularExpression) // 移除可能的JSON字符
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                return withoutPrefix.isEmpty ? nil : withoutPrefix
            }
        
        return lines.filter { !$0.isEmpty }
    }
    
    private func callGeminiAPI(prompt: String, apiKey: String) async throws -> String {
        guard let url = URL(string: "\(geminiFlashBaseURL)?key=\(apiKey)") else {
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

// 解析历史人物JSON响应的模型
struct PersonsResponse: Decodable {
    let persons: [String]
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