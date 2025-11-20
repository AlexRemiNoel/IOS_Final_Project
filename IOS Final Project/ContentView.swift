//
//  ContentView.swift
//  IOS Final Project
//
//  Created by macuser on 2025-11-06.
//

public import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var library = LibraryViewModel()
    @StateObject private var player = PlayerViewModel()

    var body: some View {
        TabView {
            LibraryView()
                .tabItem { Label("Library", systemImage: "music.note.list") }
                .environmentObject(library)
                .environmentObject(player)

            PlaylistsView()
                .tabItem { Label("Playlists", systemImage: "music.note") }
                .environmentObject(library)
                .environmentObject(player)

            NowPlayingView()
                .tabItem { Label("Now Playing", systemImage: "play.circle") }
                .environmentObject(player)
        }
    }
}

struct LibraryView: View {
    @EnvironmentObject private var library: LibraryViewModel
    @EnvironmentObject private var player: PlayerViewModel
    @State private var importing = false

    var body: some View {
        NavigationStack {
            List {
                if library.tracks.isEmpty {
                    ContentUnavailableView("No Music", systemImage: "music.note", description: Text("Import MP3 files using the + button."))
                } else {
                    ForEach(library.tracks) { track in
                        Button {
                            player.play(track: track)
                        } label: {
                            HStack {
                                Image(systemName: "music.note")
                                VStack(alignment: .leading) {
                                    Text(track.title)
                                    if let d = track.duration { Text(Self.format(d)).font(.caption).foregroundStyle(.secondary) }
                                }
                                Spacer()
                                if player.currentTrack?.id == track.id && player.isPlaying {
                                    Image(systemName: "waveform.and.magnifyingglass")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        library.rescanSongs()
                    } label: {
                        Label("Rescan", systemImage: "arrow.clockwise")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { importing = true } label: { Image(systemName: "plus") }
                }
            }
            .fileImporter(isPresented: $importing, allowedContentTypes: [UTType.mp3, UTType.audio], allowsMultipleSelection: true) { result in
                switch result {
                case .success(let urls):
                    Task { await library.importTracks(from: urls) }
                case .failure(let error):
                    print("Import failed: \(error)")
                }
            }
        }
    }

    static func format(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

struct PlaylistsView: View {
    @EnvironmentObject private var library: LibraryViewModel
    @EnvironmentObject private var player: PlayerViewModel
    @State private var creating = false
    @State private var newName = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(library.playlists) { playlist in
                    HStack {
                        NavigationLink(playlist.name) {
                            PlaylistDetailView(playlist: playlist)
                        }
                        Spacer()
                        Button(action: {
                            if let first = library.tracks(in: playlist).first {
                                player.play(track: first)
                            }
                        }) {
                            Image(systemName: "play.circle.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Play")
                    }
                }
                .onDelete(perform: library.deletePlaylists)
            }
            .navigationTitle("Playlists")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { creating = true } label: { Image(systemName: "plus") }
                }
            }
            .alert("New Playlist", isPresented: $creating) {
                TextField("Name", text: $newName)
                Button("Create") {
                    let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !name.isEmpty { library.addPlaylist(named: name) }
                    newName = ""
                }
                Button("Cancel", role: .cancel) { newName = "" }
            } message: {
                Text("Enter a name for your playlist")
            }
        }
    }
}

struct PlaylistDetailView: View {
    @EnvironmentObject private var library: LibraryViewModel
    @EnvironmentObject private var player: PlayerViewModel
    let playlist: Playlist

    var body: some View {
        List {
            Section("Tracks") {
                ForEach(library.tracks(in: playlist)) { track in
                    Button {
                        player.play(track: track)
                    } label: {
                        HStack {
                            Image(systemName: "music.note")
                            Text(track.title)
                            Spacer()
                        }
                    }
                }
            }

            Section("Add from Library") {
                ForEach(library.tracks) { track in
                    Button {
                        library.add(track: track, to: playlist)
                    } label: {
                        HStack {
                            Image(systemName: library.tracks(in: playlist).contains(track) ? "checkmark.circle.fill" : "plus.circle")
                                .foregroundStyle(.blue)
                            Text(track.title)
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle(playlist.name)
    }
}

struct NowPlayingView: View {
    @EnvironmentObject private var player: PlayerViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)

            if let track = player.currentTrack {
                VStack(spacing: 16) {
                    Text(track.title)
                        .font(.title2).bold()
                        .multilineTextAlignment(.center)

                    VStack {
                        Slider(value: Binding(
                            get: { player.currentTime },
                            set: { player.seek(to: $0) }
                        ), in: 0...max(player.duration, 1))
                        HStack {
                            Text(LibraryView.format(player.currentTime))
                            Spacer()
                            Text(LibraryView.format(player.duration))
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 32) {
                        Button(action: { player.togglePlayPause() }) {
                            Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 56))
                        }
                        .accessibilityLabel(player.isPlaying ? "Pause" : "Play")

                        Button(role: .destructive, action: { player.stop() }) {
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: 40))
                        }
                        .accessibilityLabel("Stop")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
            } else {
                ContentUnavailableView("Nothing Playing", systemImage: "play.circle", description: Text("Select a track from your Library or a Playlist."))
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Now Playing")
    }
}

#Preview {
    ContentView()
}
