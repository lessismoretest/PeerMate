import SwiftUI
import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var responses: [UUID: String] = [:]
    @Published var isLoading: [UUID: Bool] = [:]
    @Published var errors: [UUID: Error] = [:]
    
    @AppStorage("birthDate") private var birthDate = Date()
    private var cancellables = Set<AnyCancellable>()
    
    func fetchResponses(for people: [Person], using config: AIConfig, forceRefresh: Bool = false) {
        let userAge = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        
        // 如果不是强制刷新，先尝试从缓存加载
        if !forceRefresh {
            let cachedResponses = CacheService.shared.loadFromCache()
            for person in people {
                if let cached = cachedResponses[person.id], !cached.isExpired {
                    responses[person.id] = cached.response
                    continue
                }
                fetchResponseForPerson(person, userAge: userAge, config: config)
            }
        } else {
            // 强制刷新所有响应
            for person in people {
                fetchResponseForPerson(person, userAge: userAge, config: config)
            }
        }
    }
    
    private func fetchResponseForPerson(_ person: Person, userAge: Int, config: AIConfig) {
        isLoading[person.id] = true
        errors[person.id] = nil
        
        Task {
            do {
                let response = try await AIService.shared.generateResponse(
                    for: person,
                    userAge: userAge,
                    using: config
                )
                responses[person.id] = response
                isLoading[person.id] = false
                
                // 保存到缓存
                CacheService.shared.saveToCache(personId: person.id, response: response)
            } catch {
                errors[person.id] = error
                isLoading[person.id] = false
            }
        }
    }
    
    func refreshAll(people: [Person], using config: AIConfig) {
        fetchResponses(for: people, using: config, forceRefresh: true)
    }
} 