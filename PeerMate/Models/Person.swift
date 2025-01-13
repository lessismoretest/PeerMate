import Foundation
import SwiftUI

struct Person: Identifiable, Codable {
    let id: UUID
    var name: String
    var index: Int?
    private var hasAvatar: Bool
    
    var avatarData: Data? {
        get {
            try? Data(contentsOf: avatarURL)
        }
        set {
            if let data = newValue {
                if let image = NSImage(data: data) {
                    if let compressed = image.compressed() {
                        try? compressed.write(to: avatarURL)
                        hasAvatar = true
                        return
                    }
                }
            }
            try? FileManager.default.removeItem(at: avatarURL)
            hasAvatar = false
        }
    }
    
    private var avatarURL: URL {
        FileManager.avatarsDirectory.appendingPathComponent("\(id.uuidString).jpg")
    }
    
    init(id: UUID = UUID(), name: String, avatarData: Data? = nil, index: Int? = nil) {
        self.id = id
        self.name = name
        self.index = index
        self.hasAvatar = false
        self.avatarData = avatarData
    }
    
    var avatar: Image {
        if hasAvatar, let data = avatarData, let image = NSImage(data: data) {
            return Image(nsImage: image)
        }
        return Image(systemName: "person.circle.fill")
    }
}

extension NSImage {
    func compressed(maxSize: Int = 300 * 1024) -> Data? {
        guard let tiffData = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }
        
        var compression: Float = 0.9
        var data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: compression])
        
        while data?.count ?? 0 > maxSize && compression > 0.1 {
            compression -= 0.1
            data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: compression])
        }
        
        return data
    }
} 