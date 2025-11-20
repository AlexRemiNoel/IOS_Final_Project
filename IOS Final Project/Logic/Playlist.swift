//
//  Playlist.swift
//  IOS Final Project
//
//  Created by Assistant on 2025-11-20.
//

import Foundation
import AVFoundation
import Combine

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

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published private(set) var tracks: [Track] = []
    @Published private(set) var playlists: [Playlist] = []

    private let libraryURL: URL
    private let tracksDirectory: URL
    private let songsDirectory: URL

    struct Snapshot: Codable {
        var tracks: [Track]
        var playlists: [Playlist]
    }

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.libraryURL = docs.appendingPathComponent("library.json")
        self.tracksDirectory = docs.appendingPathComponent("Tracks", isDirectory: true)
        self.songsDirectory = docs.appendingPathComponent("Songs", isDirectory: true)
        createTracksDirectoryIfNeeded()
        createSongsDirectoryIfNeeded()
        load()
        importBundleSongsIfNeeded()
        scanSongsFolder()
        save()
    }

    // MARK: - Import / CRUD

    func importTracks(from urls: [URL]) async {
        for url in urls {
            await importSingle(url: url)
        }
        save()
    }

    private func importSingle(url: URL) async {
        do {
            let uniqueName = uniqueFileName(for: url.lastPathComponent)
            let destination = tracksDirectory.appendingPathComponent(uniqueName)
            // If the source is a security-scoped URL (e.g., from Files), try to access it temporarily.
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            // Copy into sandbox (replace if needed)
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: url, to: destination)

            // Read duration
            let asset = AVURLAsset(url: destination)
            var durationSeconds: TimeInterval? = nil
            let duration = asset.duration
            if duration.isValid && duration.seconds.isFinite && duration.seconds > 0 {
                durationSeconds = duration.seconds
            }

            let title = destination.deletingPathExtension().lastPathComponent
            let relative = "Tracks/" + uniqueName
            let track = Track(title: title, relativePath: relative, duration: durationSeconds)
            tracks.append(track)
        } catch {
            print("Failed to import track: \(error)")
        }
    }

    func addPlaylist(named name: String) {
        let playlist = Playlist(name: name)
        playlists.append(playlist)
        save()
    }

    func deletePlaylists(at offsets: IndexSet) {
        let sorted = offsets.sorted(by: >)
        for index in sorted {
            guard playlists.indices.contains(index) else { continue }
            playlists.remove(at: index)
        }
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

    // MARK: - Helpers

    private func createTracksDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: tracksDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: tracksDirectory, withIntermediateDirectories: true)
            } catch {
                print("Failed to create Tracks directory: \(error)")
            }
        }
    }

    private func uniqueFileName(for originalName: String) -> String {
        let base = URL(fileURLWithPath: originalName).deletingPathExtension().lastPathComponent
        let ext = URL(fileURLWithPath: originalName).pathExtension
        var candidate = originalName
        var idx = 1
        while FileManager.default.fileExists(atPath: tracksDirectory.appendingPathComponent(candidate).path) {
            candidate = "\(base) \(idx).\(ext)"
            idx += 1
        }
        return candidate
    }

    // MARK: - Songs folder detection

    private func scanSongsFolder() {
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: songsDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            for fileURL in urls where isAudioFile(fileURL) {
                let relative = "Songs/" + fileURL.lastPathComponent
                // Avoid duplicates by relative path
                if tracks.contains(where: { $0.relativePath == relative }) { continue }

                // Read duration
                let asset = AVURLAsset(url: fileURL)
                var durationSeconds: TimeInterval? = nil
                let duration = asset.duration
                if duration.isValid && duration.seconds.isFinite && duration.seconds > 0 {
                    durationSeconds = duration.seconds
                }

                let title = fileURL.deletingPathExtension().lastPathComponent
                let track = Track(title: title, relativePath: relative, duration: durationSeconds)
                tracks.append(track)
            }
        } catch {
            print("Failed to scan Songs folder: \(error)")
        }
    }

    /// Copy any audio files from the app bundle's Resources/Songs into Documents/Songs (first run or when new files are added to bundle).
    private func importBundleSongsIfNeeded() {
        guard let bundleURLs = Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: "Songs") else { return }
        for src in bundleURLs where isAudioFile(src) {
            let dst = songsDirectory.appendingPathComponent(src.lastPathComponent)
            if !FileManager.default.fileExists(atPath: dst.path) {
                do { try FileManager.default.copyItem(at: src, to: dst) } catch { print("Failed to copy bundle song: \(error)") }
            }
        }
    }

    private func isAudioFile(_ url: URL) -> Bool {
        let exts = ["mp3", "m4a", "aac", "wav", "aiff", "caf"]
        return exts.contains(url.pathExtension.lowercased())
    }

    private func createSongsDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: songsDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: songsDirectory, withIntermediateDirectories: true)
            } catch {
                print("Failed to create Songs directory: \(error)")
            }
        }
    }

    private func uniqueFileName(in directory: URL, for originalName: String) -> String {
        let base = URL(fileURLWithPath: originalName).deletingPathExtension().lastPathComponent
        let ext = URL(fileURLWithPath: originalName).pathExtension
        var candidate = originalName
        var idx = 1
        while FileManager.default.fileExists(atPath: directory.appendingPathComponent(candidate).path) {
            candidate = "\(base) \(idx).\(ext)"
            idx += 1
        }
        return candidate
    }
    
    // MARK: - Public API

    func rescanSongs() {
        scanSongsFolder()
        save()
    }
}
