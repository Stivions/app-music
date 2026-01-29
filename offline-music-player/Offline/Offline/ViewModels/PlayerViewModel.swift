import Foundation
import SwiftUI
import Combine

@MainActor
class PlayerViewModel: ObservableObject {
    @Published var currentSong: Song?
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var showFullPlayer = false
    
    private var playlist: [Song] = []
    private var currentIndex: Int = 0
    
    private let audioService = AudioPlayerService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        audioService.$isPlaying
            .receive(on: DispatchQueue.main)
            .assign(to: &$isPlaying)
        
        audioService.$currentTime
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentTime)
        
        audioService.$duration
            .receive(on: DispatchQueue.main)
            .assign(to: &$duration)
        
        audioService.onSongFinished = { [weak self] in
            Task { @MainActor in
                self?.playNext()
            }
        }
    }
    
    func playSong(_ song: Song, playlist: [Song]) {
        self.playlist = playlist
        self.currentIndex = playlist.firstIndex(where: { $0.id == song.id }) ?? 0
        self.currentSong = song
        
        audioService.loadSong(song)
        audioService.play()
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    func togglePlayPause() {
        audioService.togglePlayPause()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    func playNext() {
        guard !playlist.isEmpty else { return }
        
        currentIndex = (currentIndex + 1) % playlist.count
        let nextSong = playlist[currentIndex]
        currentSong = nextSong
        
        audioService.loadSong(nextSong)
        audioService.play()
    }
    
    func playPrevious() {
        guard !playlist.isEmpty else { return }
        
        if currentTime > 3 {
            audioService.seekToBeginning()
            return
        }
        
        currentIndex = currentIndex > 0 ? currentIndex - 1 : playlist.count - 1
        let previousSong = playlist[currentIndex]
        currentSong = previousSong
        
        audioService.loadSong(previousSong)
        audioService.play()
    }
    
    func seek(to time: TimeInterval) {
        audioService.seek(to: time)
    }
    
    func stop() {
        audioService.stop()
        currentSong = nil
        playlist = []
        currentIndex = 0
    }
    
    func updateCurrentSong(_ song: Song) {
        if currentSong?.id == song.id {
            currentSong = song
            audioService.updateNowPlaying(for: song)
            
            if let index = playlist.firstIndex(where: { $0.id == song.id }) {
                playlist[index] = song
            }
        }
    }
    
    func removeSongFromPlaylist(_ song: Song) {
        if currentSong?.id == song.id {
            if playlist.count > 1 {
                playNext()
                playlist.removeAll { $0.id == song.id }
                if currentIndex >= playlist.count {
                    currentIndex = 0
                }
            } else {
                stop()
            }
        } else {
            playlist.removeAll { $0.id == song.id }
            if let current = currentSong, let newIndex = playlist.firstIndex(where: { $0.id == current.id }) {
                currentIndex = newIndex
            }
        }
    }
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        guard !time.isNaN && !time.isInfinite else { return "0:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
