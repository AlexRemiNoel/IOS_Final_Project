//
//  Track.swift
//  IOS Final Project
//
//  Created by Assistant on 2025-11-20.
//

import Foundation
import AVFoundation

struct Track: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    /// Relative path inside the app's Documents directory (e.g., "Tracks/filename.mp3")
    var relativePath: String
    /// Cached duration in seconds (optional)
    var duration: TimeInterval?

    init(id: UUID = UUID(), title: String, relativePath: String, duration: TimeInterval? = nil) {
        self.id = id
        self.title = title
        self.relativePath = relativePath
        self.duration = duration
    }

    /// Returns the file URL inside the app's sandbox for this track.
    func fileURL() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(relativePath)
    }
}
