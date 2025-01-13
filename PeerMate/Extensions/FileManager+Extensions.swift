import Foundation

extension FileManager {
    static var avatarsDirectory: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportURL = paths[0].appendingPathComponent("PeerMate/Avatars")
        try? FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        return appSupportURL
    }
} 