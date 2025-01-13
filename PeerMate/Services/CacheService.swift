import Foundation

class CacheService {
    static let shared = CacheService()
    private init() {}
    
    private let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    private let cacheFileName = "responses_cache.json"
    
    private var cacheURL: URL {
        cacheDirectory.appendingPathComponent(cacheFileName)
    }
    
    struct CachedResponse: Codable {
        let personId: UUID
        let response: String
        let timestamp: Date
        
        var isExpired: Bool {
            // 检查是否过了今天
            !Calendar.current.isDate(timestamp, inSameDayAs: Date())
        }
    }
    
    func saveToCache(personId: UUID, response: String) {
        var cachedResponses = loadFromCache()
        cachedResponses[personId] = CachedResponse(
            personId: personId,
            response: response,
            timestamp: Date()
        )
        
        do {
            let data = try JSONEncoder().encode(cachedResponses)
            try data.write(to: cacheURL)
        } catch {
            print("Failed to save cache:", error)
        }
    }
    
    func loadFromCache() -> [UUID: CachedResponse] {
        do {
            let data = try Data(contentsOf: cacheURL)
            let responses = try JSONDecoder().decode([UUID: CachedResponse].self, from: data)
            
            // 过滤掉过期的缓存
            return responses.filter { !$0.value.isExpired }
        } catch {
            return [:]
        }
    }
    
    func clearCache() {
        try? FileManager.default.removeItem(at: cacheURL)
    }
} 