import Foundation
import SwiftUI

@MainActor
class LibraryViewModel: ObservableObject {
    @Published var songs: [Song] = []
    @Published var isLoading = false
    @Published var isImporting = false
    @Published var importProgress: (current: Int, total: Int)?
    @Published var showDocumentPicker = false
    @Published var storageUsed: Int64 = 0
    @Published var editingSong: Song?
    
    private let libraryService = LibraryService.shared
    private let persistenceService = PersistenceService.shared
    
    init() {
        Task {
            await loadLibrary()
        }
    }
    
    func loadLibrary() async {
        isLoading = true
        songs = await persistenceService.loadLibrary()
        storageUsed = await persistenceService.calculateStorageUsed()
        isLoading = false
    }
    
    func importFiles(from urls: [URL]) async {
        isImporting = true
        importProgress = (0, urls.count)
        
        let existingHashes = Set(songs.map { $0.fileHash })
        
        let importedSongs = await libraryService.importFiles(from: urls, existingHashes: existingHashes) { current, total in
            Task { @MainActor in
                self.importProgress = (current, total)
            }
        }
        
        songs.append(contentsOf: importedSongs)
        songs.sort { $0.dateAdded > $1.dateAdded }
        
        await persistenceService.saveLibrary(songs)
        storageUsed = await persistenceService.calculateStorageUsed()
        
        isImporting = false
        importProgress = nil
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    func deleteSong(_ song: Song) async {
        _ = await libraryService.deleteSong(song)
        songs.removeAll { $0.id == song.id }
        await persistenceService.saveLibrary(songs)
        storageUsed = await persistenceService.calculateStorageUsed()
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    func updateSong(_ song: Song) async {
        if let index = songs.firstIndex(where: { $0.id == song.id }) {
            songs[index] = song
            await persistenceService.saveLibrary(songs)
        }
    }
    
    func deleteAllData() async {
        await persistenceService.deleteAllData()
        songs = []
        storageUsed = 0
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    var formattedStorageUsed: String {
        ByteCountFormatter.string(fromByteCount: storageUsed, countStyle: .file)
    }
}
