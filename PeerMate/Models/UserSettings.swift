import Foundation
import SwiftUI

class UserSettings: ObservableObject {
    @Published var people: [Person] {
        didSet {
            savePeople()
        }
    }
    @Published var aiConfig: AIConfig {
        didSet {
            saveAIConfig()
        }
    }
    
    init() {
        self.people = UserDefaults.standard.people ?? []
        self.aiConfig = UserDefaults.standard.aiConfig ?? AIConfig(
            selectedModel: AIModel.geminiFlash.rawValue,
            geminiApiKey: "",
            deepseekApiKey: ""
        )
    }
    
    private func savePeople() {
        UserDefaults.standard.people = people
    }
    
    private func saveAIConfig() {
        UserDefaults.standard.aiConfig = aiConfig
    }
    
    deinit {
        cleanupUnusedAvatars()
    }
    
    private func cleanupUnusedAvatars() {
        let usedIds = Set(people.map { $0.id.uuidString })
        let avatarsDir = FileManager.avatarsDirectory
        
        if let files = try? FileManager.default.contentsOfDirectory(at: avatarsDir, includingPropertiesForKeys: nil) {
            for file in files {
                let filename = file.deletingPathExtension().lastPathComponent
                if !usedIds.contains(filename) {
                    try? FileManager.default.removeItem(at: file)
                }
            }
        }
    }
} 