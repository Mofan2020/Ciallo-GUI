//
//  AudioManager.swift
//  Ciallo
//
//  Created by 星空喵 on 2026/5/1.
//

import Foundation
import AVFoundation
import Combine

struct AudioFile: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let url: URL
    let index: Int
}

final class AudioManager: ObservableObject {
    @Published var isPlaying = false
    @Published var currentVolume: Float = 1.0
    @Published var currentFile: AudioFile?
    @Published var isLooping = false
    @Published var isRandom = false
    @Published var files: [AudioFile] = []

    private var audioPlayer: AVAudioPlayer?

    func loadFiles(from folderURL: URL) {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else { return }

        var audioFiles: [AudioFile] = []

        for fileURL in contents where fileURL.pathExtension.lowercased() == "mp3" {
            let fileName = fileURL.deletingPathExtension().lastPathComponent
            if let index = Int(fileName.suffix(5)) {
                let audioFile = AudioFile(name: fileName, url: fileURL, index: index)
                audioFiles.append(audioFile)
            }
        }

        files = audioFiles.sorted { $0.index < $1.index }
        if let first = files.first {
            selectFile(first)
        }
    }

    func selectFile(_ file: AudioFile) {
        currentFile = file
        guard let player = try? AVAudioPlayer(contentsOf: file.url) else { return }
        audioPlayer = player
        player.volume = currentVolume
        player.prepareToPlay()
    }

    func togglePlayPause() {
        guard let player = audioPlayer else { return }

        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }

    func setVolume(_ volume: Float) {
        currentVolume = volume
        audioPlayer?.volume = volume
    }

    func playRandom() {
        guard let randomFile = files.randomElement() else { return }
        selectFile(randomFile)
        audioPlayer?.play()
        isPlaying = true
    }

    func playNext() {
        guard let current = currentFile,
              let currentIndex = files.firstIndex(where: { $0.id == current.id }) else { return }

        let nextIndex = isRandom
            ? Int.random(in: 0..<files.count)
            : (currentIndex + 1) % files.count

        selectFile(files[nextIndex])
        if isPlaying {
            audioPlayer?.play()
        }
    }
}
