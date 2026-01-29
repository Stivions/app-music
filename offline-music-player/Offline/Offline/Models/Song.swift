import Foundation

struct Song: Identifiable, Codable, Equatable {
    let id: UUID
    let fileHash: String
    let localFileName: String
    let originalTitle: String
    let originalArtist: String?
    let duration: TimeInterval
    let artworkData: Data?
    let dateAdded: Date
    
    var customTitle: String?
    var customArtist: String?
    var customArtworkData: Data?
    
    var displayTitle: String {
        customTitle ?? originalTitle
    }
    
    var displayArtist: String {
        customArtist ?? originalArtist ?? "Unknown Artist"
    }
    
    var displayArtwork: Data? {
        customArtworkData ?? artworkData
    }
    
    var localFileURL: URL {
        FileManager.musicDirectory.appendingPathComponent(localFileName)
    }
    
    init(
        id: UUID = UUID(),
        fileHash: String,
        localFileName: String,
        originalTitle: String,
        originalArtist: String? = nil,
        duration: TimeInterval,
        artworkData: Data? = nil,
        dateAdded: Date = Date(),
        customTitle: String? = nil,
        customArtist: String? = nil,
        customArtworkData: Data? = nil
    ) {
        self.id = id
        self.fileHash = fileHash
        self.localFileName = localFileName
        self.originalTitle = originalTitle
        self.originalArtist = originalArtist
        self.duration = duration
        self.artworkData = artworkData
        self.dateAdded = dateAdded
        self.customTitle = customTitle
        self.customArtist = customArtist
        self.customArtworkData = customArtworkData
    }
    
    static func == (lhs: Song, rhs: Song) -> Bool {
        lhs.id == rhs.id
    }
}

extension FileManager {
    static var applicationSupportDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    }
    
    static var musicDirectory: URL {
        let dir = applicationSupportDirectory.appendingPathComponent("Music", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    static var libraryFileURL: URL {
        applicationSupportDirectory.appendingPathComponent("library.json")
    }
}
