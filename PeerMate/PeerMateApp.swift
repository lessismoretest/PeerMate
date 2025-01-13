//
//  PeerMateApp.swift
//  PeerMate
//
//  Created by Less is more on 2025/1/14.
//

import SwiftUI

@main
struct PeerMateApp: App {
    @AppStorage("appearance") private var appearance: Appearance = .system
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 800, minHeight: 600)
                .preferredColorScheme(appearance.colorScheme)
        }
    }
}
