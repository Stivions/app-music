import Foundation

actor PersistenceService {
    static let shared = PersistenceService()
    
    private init() {}
    
    func loadLibrary() async -> [Song] {
        let url = FileManager.libraryFileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let songs = try JSONDecoder().decode([Song].self, from: data)
            return songs
        } catch {
            print("Failed to load library: \(error)")
            return []
        }
    }
    
    func saveLibrary(_ songs: [Song]) async {
        let url = FileManager.libraryFileURL
        
        do {
            let data = try JSONEncoder().encode(songs)
            try data.write(to: url, options: .atomic)
        } catch {
            print("Failed to save library: \(error)")
        }
    }
    
    func calculateStorageUsed() async -> Int64 {
        let musicDir = FileManager.musicDirectory
        var totalSize: Int64 = 0
        
        guard let enumerator = FileManager.default.enumerator(at: musicDir, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(resourceValues.fileSize ?? 0)
            } catch {
                continue
            }
        }
        
        return totalSize
    }
    
    func deleteAllData() async {
        let musicDir = FileManager.musicDirectory
        let libraryURL = FileManager.libraryFileURL
        
        try? FileManager.default.removeItem(at: musicDir)
        try? FileManager.default.removeItem(at: libraryURL)
        
        try? FileManager.default.createDirectory(at: musicDir, withIntermediateDirectories: true)
    }
}
