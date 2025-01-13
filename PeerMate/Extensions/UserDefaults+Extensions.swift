import Foundation

extension UserDefaults {
    var people: [Person]? {
        get {
            guard let data = data(forKey: "people") else { return nil }
            return try? JSONDecoder().decode([Person].self, from: data)
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            set(data, forKey: "people")
        }
    }
    
    var aiConfig: AIConfig? {
        get {
            guard let data = data(forKey: "aiConfig") else { return nil }
            return try? JSONDecoder().decode(AIConfig.self, from: data)
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            set(data, forKey: "aiConfig")
        }
    }
} 