import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var libraryViewModel: LibraryViewModel
    @EnvironmentObject var playerViewModel: PlayerViewModel
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                List {
                    Section {
                        HStack {
                            Label("Songs", systemImage: "music.note")
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(libraryViewModel.songs.count)")
                                .foregroundStyle(.gray)
                        }
                        .listRowBackground(Color.gray.opacity(0.15))
                        
                        HStack {
                            Label("Storage Used", systemImage: "internaldrive")
                                .foregroundStyle(.white)
                            Spacer()
                            Text(libraryViewModel.formattedStorageUsed)
                                .foregroundStyle(.gray)
                        }
                        .listRowBackground(Color.gray.opacity(0.15))
                    } header: {
                        Text("Library")
                            .foregroundStyle(.gray)
                    }
                    
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete All Music", systemImage: "trash")
                                .foregroundStyle(.red)
                        }
                        .listRowBackground(Color.gray.opacity(0.15))
                    } header: {
                        Text("Data")
                            .foregroundStyle(.gray)
                    }
                    
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Offline")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("A personal music player")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                            Text("100% offline • No tracking • No ads")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color.gray.opacity(0.15))
                    } header: {
                        Text("About")
                            .foregroundStyle(.gray)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.blue)
                }
            }
            .alert("Delete All Music?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete All", role: .destructive) {
                    Task {
                        playerViewModel.stop()
                        await libraryViewModel.deleteAllData()
                    }
                }
            } message: {
                Text("This will permanently delete all imported songs. This cannot be undone.")
            }
        }
    }
}
