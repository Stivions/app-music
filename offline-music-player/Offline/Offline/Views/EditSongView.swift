import SwiftUI
import PhotosUI

struct EditSongView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var libraryViewModel: LibraryViewModel
    @EnvironmentObject var playerViewModel: PlayerViewModel
    
    let song: Song
    
    @State private var customTitle: String
    @State private var customArtist: String
    @State private var customArtworkData: Data?
    @State private var showPhotoPicker = false
    @State private var showFilePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    init(song: Song) {
        self.song = song
        _customTitle = State(initialValue: song.customTitle ?? song.originalTitle)
        _customArtist = State(initialValue: song.customArtist ?? song.originalArtist ?? "")
        _customArtworkData = State(initialValue: song.customArtworkData)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        artworkSection
                        
                        textFieldsSection
                        
                        Spacer()
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Edit Song")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.gray)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
                }
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        customArtworkData = data
                    }
                }
            }
            .sheet(isPresented: $showFilePicker) {
                ImageFilePicker { data in
                    customArtworkData = data
                }
            }
        }
    }
    
    private var artworkSection: some View {
        VStack(spacing: 16) {
            Group {
                if let artworkData = displayArtwork,
                   let uiImage = UIImage(data: artworkData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        Color.gray.opacity(0.2)
                        Image(systemName: "music.note")
                            .font(.system(size: 48))
                            .foregroundStyle(.gray)
                    }
                }
            }
            .frame(width: 200, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            HStack(spacing: 16) {
                Button {
                    showPhotoPicker = true
                } label: {
                    Label("Photos", systemImage: "photo")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Capsule())
                }
                
                Button {
                    showFilePicker = true
                } label: {
                    Label("Files", systemImage: "folder")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Capsule())
                }
                
                if customArtworkData != nil {
                    Button {
                        customArtworkData = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Color.red.opacity(0.8))
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
    
    private var textFieldsSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                
                TextField("Song title", text: $customTitle)
                    .font(.body)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Artist")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                
                TextField("Artist name", text: $customArtist)
                    .font(.body)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
    
    private var displayArtwork: Data? {
        customArtworkData ?? song.artworkData
    }
    
    private func save() {
        var updatedSong = song
        
        let titleToSave = customTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let artistToSave = customArtist.trimmingCharacters(in: .whitespacesAndNewlines)
        
        updatedSong.customTitle = titleToSave != song.originalTitle ? titleToSave : nil
        updatedSong.customArtist = artistToSave != (song.originalArtist ?? "") ? artistToSave : nil
        updatedSong.customArtworkData = customArtworkData
        
        Task {
            await libraryViewModel.updateSong(updatedSong)
            playerViewModel.updateCurrentSong(updatedSong)
        }
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        dismiss()
    }
}

struct ImageFilePicker: UIViewControllerRepresentable {
    let onPick: (Data) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.image], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (Data) -> Void
        
        init(onPick: @escaping (Data) -> Void) {
            self.onPick = onPick
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first,
                  let data = try? Data(contentsOf: url) else { return }
            onPick(data)
        }
    }
}
