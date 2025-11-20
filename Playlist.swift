//
//  Playlist.swift
//  IOS Final Project
//
//  Created by Assistant on 2025-11-20.
//

import Foundation

struct Playlist: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var trackIDs: [UUID]

    init(id: UUID = UUID(), name: String, trackIDs: [UUID] = []) {
        self.id = id
        self.name = name
        self.trackIDs = trackIDs
    }
}

final class LibraryStore: ObservableObject {
    @Published private(set) var tracks: [Track] = []
    @Published private(set) var playlists: [Playlist] = []

    private let libraryURL: URL

    struct Snapshot: Codable {
        var tracks: [Track]
        var playlists: [Playlist]
    }

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.libraryURL = docs.appendingPathComponent("library.json")
        load()
    }

    // MARK: - CRUD

    func importTracks(from urls: [URL]) async {
        for url in urls {
            do {
                let track = try Track.fromFileURL(url)
                if !tracks.contains(where: { $0.id == track.id }) {
                    tracks.append(track)
                }
            } catch {
                print("Failed to import track: \(error)")
            }
        }
        save()
    }

    func addPlaylist(named name: String) {
        let playlist = Playlist(name: name)
        playlists.append(playlist)
        save()
    }

    func deletePlaylists(at offsets: IndexSet) {
        playlists.remove(atOffsets: offsets)
        save()
    }

    func renamePlaylist(_ playlist: Playlist, to newName: String) {
        guard let idx = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        playlists[idx].name = newName
        save()
    }

    func add(track: Track, to playlist: Playlist) {
        guard let pIdx = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        if !playlists[pIdx].trackIDs.contains(track.id) {
            playlists[pIdx].trackIDs.append(track.id)
            save()
        }
    }

    func remove(track: Track, from playlist: Playlist) {
        guard let pIdx = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        playlists[pIdx].trackIDs.removeAll { $0 == track.id }
        save()
    }

    func tracks(in playlist: Playlist) -> [Track] {
        tracks.filter { playlist.trackIDs.contains($0.id) }
    }

    // MARK: - Persistence

    private func load() {
        guard FileManager.default.fileExists(atPath: libraryURL.path) else { return }
        do {
            let data = try Data(contentsOf: libraryURL)
            let snapshot = try JSONDecoder().decode(Snapshot.self, from: data)
            self.tracks = snapshot.tracks
            self.playlists = snapshot.playlists
        } catch {
            print("Failed to load library: \(error)")
        }
    }

    private func save() {
        do {
            let snapshot = Snapshot(tracks: tracks, playlists: playlists)
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: libraryURL, options: [.atomic])
        } catch {
            print("Failed to save library: \(error)")
        }
    }
}

