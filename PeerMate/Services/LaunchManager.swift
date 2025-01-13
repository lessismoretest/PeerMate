import Foundation
import ServiceManagement

class LaunchManager {
    static let shared = LaunchManager()
    private init() {}
    
    private let launcherAppId = "com.zisa.PeerMateLauncher"
    
    var isEnabled: Bool {
        get {
            SMAppService.mainApp.status == .enabled
        }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to set launch at login:", error)
            }
        }
    }
} 