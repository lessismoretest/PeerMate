import SwiftUI

struct Sidebar: View {
    @Binding var selection: SidebarTab
    
    var body: some View {
        List(selection: $selection) {
            // 顶部应用名标题
            Text("PeerMate")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
                .padding(.horizontal, 4)
                .listRowSeparator(.hidden)
            
            NavigationLink(value: SidebarTab.home) {
                Label("首页", systemImage: "house")
            }
            
            NavigationLink(value: SidebarTab.people) {
                Label("人物", systemImage: "person.2")
            }
            
            NavigationLink(value: SidebarTab.history) {
                Label("历史", systemImage: "clock")
            }
            
            NavigationLink(value: SidebarTab.settings) {
                Label("设置", systemImage: "gear")
            }
        }
        .listStyle(SidebarListStyle())
    }
} 