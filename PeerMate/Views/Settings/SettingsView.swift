import SwiftUI

struct SettingsView: View {
    @State private var selectedCategory: SettingsCategory? = .appearance
    
    var body: some View {
        NavigationSplitView {
            // 左侧分类列表
            List(SettingsCategory.allCases, selection: $selectedCategory) { category in
                NavigationLink(value: category) {
                    Label(category.name, systemImage: category.icon)
                }
            }
            .navigationTitle("设置")
        } detail: {
            // 右侧具体设置内容
            if let category = selectedCategory {
                SettingsDetailView(category: category)
            } else {
                Text("请选择设置类别")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// 设置类别
enum SettingsCategory: String, CaseIterable, Identifiable {
    case appearance = "外观"
    case personal = "个人信息"
    case ai = "AI 设置"
    
    var id: String { rawValue }
    
    var name: String { rawValue }
    
    var icon: String {
        switch self {
        case .appearance:
            return "paintbrush"
        case .personal:
            return "person.circle"
        case .ai:
            return "cpu"
        }
    }
}

// 右侧详细设置视图
struct SettingsDetailView: View {
    let category: SettingsCategory
    @AppStorage("appearance") private var appearance: Appearance = .system
    @AppStorage("birthDate") private var birthDate = Date()
    @StateObject private var userSettings = UserSettings()
    
    var body: some View {
        Form {
            switch category {
            case .appearance:
                Section {
                    Picker("主题", selection: $appearance) {
                        ForEach(Appearance.allCases) { appearance in
                            Text(appearance.name).tag(appearance)
                        }
                    }
                }
                
            case .personal:
                Section {
                    DatePicker("出生日期", selection: $birthDate, displayedComponents: .date)
                }
                
            case .ai:
                Section {
                    AISettingsView(userSettings: userSettings)
                }
            }
        }
        .padding()
        .navigationTitle(category.name)
    }
}

// MARK: - AI设置视图
private struct AISettingsView: View {
    @ObservedObject var userSettings: UserSettings
    
    var body: some View {
        Picker("AI 模型", selection: $userSettings.aiConfig.selectedModel) {
            ForEach(AIModel.allCases) { model in
                Text(model.rawValue).tag(model.rawValue)
            }
        }
        
        if userSettings.aiConfig.selectedModel == AIModel.gemini.rawValue {
            SecureField("Gemini API Key", text: $userSettings.aiConfig.geminiApiKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .transition(.opacity)
        }
        
        if userSettings.aiConfig.selectedModel == AIModel.deepseek.rawValue {
            SecureField("DeepSeek API Key", text: $userSettings.aiConfig.deepseekApiKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .transition(.opacity)
        }
    }
} 