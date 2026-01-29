import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @EnvironmentObject var libraryViewModel: LibraryViewModel
    @EnvironmentObject var playerViewModel: PlayerViewModel
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if libraryViewModel.songs.isEmpty && !libraryViewModel.isLoading {
                    EmptyLibraryView()
                } else {
                    songList
                }
                
                if libraryViewModel.isImporting {
                    importingOverlay
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                            .foregroundStyle(.white)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        libraryViewModel.showDocumentPicker = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
            }
            .sheet(isPresented: $libraryViewModel.showDocumentPicker) {
                DocumentPicker { urls in
                    Task {
                        await libraryViewModel.importFiles(from: urls)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(item: $libraryViewModel.editingSong) { song in
                EditSongView(song: song)
            }
        }
    }
    
    private var songList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(libraryViewModel.songs) { song in
                    SongRowView(song: song)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            playerViewModel.playSong(song, playlist: libraryViewModel.songs)
                        }
                        .onLongPressGesture {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            libraryViewModel.editingSong = song
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task {
                                    playerViewModel.removeSongFromPlaylist(song)
                                    await libraryViewModel.deleteSong(song)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.leading, 72)
                }
            }
            .padding(.bottom, playerViewModel.currentSong != nil ? 80 : 0)
        }
    }
    
    private var importingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                if let progress = libraryViewModel.importProgress {
                    Text("Importing \(progress.current) of \(progress.total)")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            .padding(32)
            .background(Color.gray.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct SongRowView: View {
    let song: Song
    @EnvironmentObject var playerViewModel: PlayerViewModel
    
    var isCurrentSong: Bool {
        playerViewModel.currentSong?.id == song.id
    }
    
    var body: some View {
        HStack(spacing: 12) {
            artworkView
            
            VStack(alignment: .leading, spacing: 4) {
                Text(song.displayTitle)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(isCurrentSong ? .blue : .white)
                    .lineLimit(1)
                
                Text(song.displayArtist)
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if isCurrentSong && playerViewModel.isPlaying {
                if #available(iOS 17.0, *) {
                    Image(systemName: "waveform")
                        .font(.body)
                        .foregroundStyle(.blue)
                        .symbolEffect(.variableColor.iterative)
                } else {
                    Image(systemName: "waveform")
                        .font(.body)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black)
    }
    
    private var artworkView: some View {
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
                        .font(.title3)
                        .foregroundStyle(.gray)
                }
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct EmptyLibraryView: View {
    @EnvironmentObject var libraryViewModel: LibraryViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "music.note.list")
                .font(.system(size: 64))
                .foregroundStyle(.gray)
            
            VStack(spacing: 8) {
                Text("No Music Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                
                Text("Tap + to import songs from Files")
                    .font(.body)
                    .foregroundStyle(.gray)
            }
            
            Button {
                libraryViewModel.showDocumentPicker = true
            } label: {
                Label("Import Music", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(Capsule())
            }
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    let onPick: ([URL]) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.mp3, .audio, .mpeg4Audio]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: false)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: ([URL]) -> Void
        
        init(onPick: @escaping ([URL]) -> Void) {
            self.onPick = onPick
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onPick(urls)
        }
    }
}

