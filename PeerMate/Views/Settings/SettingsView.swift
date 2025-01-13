import SwiftUI
import ServiceManagement

/**
 * 设置视图
 */
struct SettingsView: View {
    @AppStorage("appearance") private var appearance: Appearance = .system
    @AppStorage("birthDate") private var birthDate = Date()
    @StateObject private var userSettings = UserSettings()
    @State private var launchAtLogin: Bool = LaunchManager.shared.isEnabled
    
    var body: some View {
        Form {
            Section {
                Picker("外观", selection: $appearance) {
                    ForEach(Appearance.allCases) { appearance in
                        Text(appearance.name).tag(appearance)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("系统设置")
            }
            
            Section {
                Toggle("开机时自动启动", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        LaunchManager.shared.isEnabled = newValue
                    }
            } header: {
                Text("通用")
            }
            
            Section {
                DatePicker("出生日期", selection: $birthDate, displayedComponents: .date)
            } header: {
                Text("个人信息")
            }
            
            Section {
                Picker("AI 模型", selection: $userSettings.aiConfig.selectedModel) {
                    ForEach(AIModel.allCases) { model in
                        Text(model.rawValue).tag(model.rawValue)
                    }
                }
                
                if userSettings.aiConfig.selectedModel == AIModel.geminiFlash.rawValue {
                    SecureField("Gemini API Key", text: $userSettings.aiConfig.geminiApiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                if userSettings.aiConfig.selectedModel == AIModel.deepseek.rawValue {
                    SecureField("DeepSeek API Key", text: $userSettings.aiConfig.deepseekApiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            } header: {
                Text("AI 设置")
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 500)
        .navigationTitle("设置")
    }
}

// GitHub 图标组件
struct GitHubIcon: View {
    var body: some View {
        Image("github")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 16, height: 16)
    }
}

extension Bundle {
    var appVersion: String {
        return "\(infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0") (\(infoDictionary?["CFBundleVersion"] as? String ?? "1"))"
    }
}

struct ExportSettingsView: View {
    var body: some View {
        Text("导出设置")
            .padding()
    }
}

struct ImportSettingsView: View {
    var body: some View {
        Text("导入设置")
            .padding()
    }
}

// 设置类别
enum SettingsCategory: String, CaseIterable, Identifiable {
    case appearance = "外观"
    case personal = "个人信息"
    case ai = "AI 设置"
    case general = "通用"
    
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
        case .general:
            return "gearshape"
        }
    }
}

// 右侧详细设置视图
struct SettingsDetailView: View {
    let category: SettingsCategory
    @AppStorage("appearance") private var appearance: Appearance = .system
    @AppStorage("birthDate") private var birthDate = Date()
    @StateObject private var userSettings = UserSettings()
    @State private var launchAtLogin: Bool = LaunchManager.shared.isEnabled
    
    var body: some View {
        Form {
            switch category {
            case .appearance:
                Picker("主题", selection: $appearance) {
                    ForEach(Appearance.allCases) { appearance in
                        Text(appearance.name).tag(appearance)
                    }
                }
                
            case .personal:
                DatePicker("出生日期", selection: $birthDate, displayedComponents: .date)
                
            case .ai:
                AISettingsView(userSettings: userSettings)
                
            case .general:
                Toggle("开机时自动启动", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        LaunchManager.shared.isEnabled = newValue
                    }
            }
        }
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
        
        if userSettings.aiConfig.selectedModel == AIModel.geminiFlash.rawValue {
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