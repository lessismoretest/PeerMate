import SwiftUI

struct Sidebar: View {
    @Binding var selection: SidebarTab
    
    var body: some View {
        List(selection: $selection) {
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