import Foundation
import AVFoundation
import CryptoKit
import UniformTypeIdentifiers

actor LibraryService {
    static let shared = LibraryService()
    
    private init() {}
    
    private let supportedExtensions = ["mp3", "m4a", "aac", "wav", "aiff"]
    
    func importFiles(from urls: [URL], existingHashes: Set<String>, progress: @escaping (Int, Int) -> Void) async -> [Song] {
        var importedSongs: [Song] = []
        let validURLs = urls.filter { url in
            supportedExtensions.contains(url.pathExtension.lowercased())
        }
        
        for (index, url) in validURLs.enumerated() {
            await MainActor.run {
                progress(index + 1, validURLs.count)
            }
            
            if let song = await importSingleFile(from: url, existingHashes: existingHashes) {
                importedSongs.append(song)
            }
        }
        
        return importedSongs
    }
    
    private func importSingleFile(from url: URL, existingHashes: Set<String>) async -> Song? {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        guard let fileData = try? Data(contentsOf: url) else {
            return nil
        }
        
        let hash = SHA256.hash(data: fileData).compactMap { String(format: "%02x", $0) }.joined()
        
        if existingHashes.contains(hash) {
            return nil
        }
        
        let fileExtension = url.pathExtension.lowercased()
        let fileName = "\(hash).\(fileExtension)"
        let destinationURL = FileManager.musicDirectory.appendingPathComponent(fileName)
        
        do {
            try fileData.write(to: destinationURL)
        } catch {
            return nil
        }
        
        let metadata = await extractMetadata(from: destinationURL, originalFileName: url.deletingPathExtension().lastPathComponent)
        
        return Song(
            fileHash: hash,
            localFileName: fileName,
            originalTitle: metadata.title,
            originalArtist: metadata.artist,
            duration: metadata.duration,
            artworkData: metadata.artwork
        )
    }
    
    private func extractMetadata(from url: URL, originalFileName: String) async -> (title: String, artist: String?, duration: TimeInterval, artwork: Data?) {
        let asset = AVAsset(url: url)
        
        var title = originalFileName
        var artist: String?
        var artwork: Data?
        var duration: TimeInterval = 0
        
        do {
            duration = try await asset.load(.duration).seconds
            
            let metadata = try await asset.load(.commonMetadata)
            
            for item in metadata {
                guard let key = item.commonKey else { continue }
                
                switch key {
                case .commonKeyTitle:
                    if let value = try? await item.load(.stringValue), !value.isEmpty {
                        title = value
                    }
                case .commonKeyArtist:
                    if let value = try? await item.load(.stringValue), !value.isEmpty {
                        artist = value
                    }
                case .commonKeyArtwork:
                    if let value = try? await item.load(.dataValue) {
                        artwork = value
                    }
                default:
                    break
                }
            }
        } catch {
            let playerItem = AVPlayerItem(url: url)
            duration = playerItem.asset.duration.seconds
        }
        
        if duration.isNaN || duration.isInfinite {
            duration = 0
        }
        
        return (title, artist, duration, artwork)
    }
    
    func deleteSong(_ song: Song) async -> Bool {
        let fileURL = song.localFileURL
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            return true
        } catch {
            return false
        }
    }
}
