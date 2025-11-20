//
//  PlayerViewModel.swift
//  IOS Final Project
//
//  Created by Assistant on 2025-11-20.
//

import Foundation
import AVFoundation
import Combine

@MainActor
final class PlayerViewModel: ObservableObject {
    @Published private(set) var currentTrack: Track?
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0

    private var player: AVAudioPlayer?
    private var timer: Timer?

    func play(track: Track) {
        stop()
        let url = track.fileURL()
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.play()
            self.player = player
            self.currentTrack = track
            self.isPlaying = true
            self.duration = player.duration
            startTimer()
        } catch {
            print("Failed to play: \(error)")
        }
    }

    func togglePlayPause() {
        guard let player = player else { return }
        if player.isPlaying { player.pause(); isPlaying = false } else { player.play(); isPlaying = true }
    }

    func stop() {
        timer?.invalidate(); timer = nil
        player?.stop()
        player = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        currentTrack = nil
    }

    func seek(to time: TimeInterval) {
        guard let player = player else { return }
        player.currentTime = time
        currentTime = time
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.player else { return }
            self.currentTime = player.currentTime
            if !player.isPlaying, self.isPlaying { // reached end
                self.isPlaying = false
            }
        }
    }
}

