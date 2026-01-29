import SwiftUI

@main
struct OfflineApp: App {
    @StateObject private var libraryViewModel = LibraryViewModel()
    @StateObject private var playerViewModel = PlayerViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(libraryViewModel)
                .environmentObject(playerViewModel)
                .preferredColorScheme(.dark)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var libraryViewModel: LibraryViewModel
    @EnvironmentObject var playerViewModel: PlayerViewModel
    
    var body: some View {
        ZStack(alignment: .bottom) {
            LibraryView()
            
            if playerViewModel.currentSong != nil {
                MiniPlayerView()
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: playerViewModel.currentSong != nil)
    }
}
