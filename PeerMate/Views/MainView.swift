import SwiftUI

struct MainView: View {
    @State private var selectedTab: SidebarTab = .home
    
    var body: some View {
        NavigationSplitView {
            Sidebar(selection: $selectedTab)
        } detail: {
            NavigationStack {
                switch selectedTab {
                case .home:
                    HomeView()
                        .navigationTitle("PeerMate - 当世界年轻时 ✨")
                case .people:
                    PeopleView()
                case .history:
                    HistoryView()
                case .settings:
                    SettingsView()
                }
            }
        }
    }
}

enum SidebarTab: String {
    case home = "首页"
    case people = "人物"
    case history = "历史"
    case settings = "设置"
} 