import SwiftUI

struct MiniPlayerView: View {
    @EnvironmentObject var playerViewModel: PlayerViewModel
    
    var body: some View {
        if let song = playerViewModel.currentSong {
            VStack(spacing: 0) {
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * playerViewModel.progress)
                }
                .frame(height: 2)
                
                HStack(spacing: 12) {
                    artworkView(for: song)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(song.displayTitle)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        
                        Text(song.displayArtist)
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Button {
                        playerViewModel.togglePlayPause()
                    } label: {
                        Image(systemName: playerViewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }
                    
                    Button {
                        playerViewModel.playNext()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.body)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .background(Color(white: 0.1))
            .onTapGesture {
                playerViewModel.showFullPlayer = true
            }
            .fullScreenCover(isPresented: $playerViewModel.showFullPlayer) {
                FullPlayerView()
            }
        }
    }
    
    private func artworkView(for song: Song) -> some View {
        Group {
            if let artworkData = song.displayArtwork,
               let uiImage = UIImage(data: artworkData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Color.gray.opacity(0.3)
                    Image(systemName: "music.note")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct FullPlayerView: View {
    @EnvironmentObject var playerViewModel: PlayerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isDragging = false
    @State private var dragValue: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let song = playerViewModel.currentSong {
                VStack(spacing: 0) {
                    header
                    
                    Spacer()
                    
                    artworkView(for: song)
                    
                    Spacer()
                    
                    songInfo(for: song)
                    
                    Spacer().frame(height: 32)
                    
                    progressView
                    
                    Spacer().frame(height: 24)
                    
                    controlsView
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            Text("Now Playing")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.gray)
            
            Spacer()
            
            Color.clear
                .frame(width: 28, height: 28)
        }
        .padding(.top, 16)
    }
    
    private func artworkView(for song: Song) -> some View {
        Group {
            if let artworkData = song.displayArtwork,
               let uiImage = UIImage(data: artworkData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ZStack {
                    Color.gray.opacity(0.2)
                    Image(systemName: "music.note")
                        .font(.system(size: 80))
                        .foregroundStyle(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
    }
    
    private func songInfo(for song: Song) -> some View {
        VStack(spacing: 4) {
            Text(song.displayTitle)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            Text(song.displayArtist)
                .font(.title3)
                .foregroundStyle(.gray)
                .lineLimit(1)
        }
    }
    
    private var progressView: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                    
                    Capsule()
                        .fill(Color.white)
                        .frame(width: max(0, geometry.size.width * (isDragging ? dragValue : playerViewModel.progress)), height: 4)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            dragValue = max(0, min(1, value.location.x / geometry.size.width))
                        }
                        .onEnded { value in
                            let progress = max(0, min(1, value.location.x / geometry.size.width))
                            let newTime = progress * playerViewModel.duration
                            playerViewModel.seek(to: newTime)
                            isDragging = false
                        }
                )
            }
            .frame(height: 4)
            
            HStack {
                Text(playerViewModel.formatTime(isDragging ? dragValue * playerViewModel.duration : playerViewModel.currentTime))
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .monospacedDigit()
                
                Spacer()
                
                Text(playerViewModel.formatTime(playerViewModel.duration))
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .monospacedDigit()
            }
        }
    }
    
    private var controlsView: some View {
        HStack(spacing: 48) {
            Button {
                playerViewModel.playPrevious()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.title)
                    .foregroundStyle(.white)
            }
            
            Button {
                playerViewModel.togglePlayPause()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 72, height: 72)
                    
                    Image(systemName: playerViewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundStyle(.black)
                        .offset(x: playerViewModel.isPlaying ? 0 : 2)
                }
            }
            
            Button {
                playerViewModel.playNext()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title)
                    .foregroundStyle(.white)
            }
        }
    }
}
