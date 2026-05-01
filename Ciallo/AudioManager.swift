//
//  AudioManager.swift
//  Ciallo
//
//  Created by 星空喵 on 2026/5/1.
//

import Foundation
import AVFoundation
import Combine

struct AudioFolder: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let url: URL
    var files: [AudioFile]
}

struct AudioFile: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let url: URL
    let index: Int
}

final class AudioManager: ObservableObject {
    @Published var isPlaying = false
    @Published var currentVolume: Float = 1.0 {
        didSet {
            audioPlayer?.volume = currentVolume
        }
    }
    @Published var currentFolder: AudioFolder?
    @Published var currentFile: AudioFile?
    @Published var isLooping = false
    @Published var isRandom = false
    @Published var availableFolders: [AudioFolder] = []
    @Published var availableFiles: [AudioFile] = []

    private var audioPlayer: AVAudioPlayer?
    private var playerTimer: Timer?

    init() {
        loadDefaultFolders()
    }

    private func loadDefaultFolders() {
        if let execPath = Bundle.main.executableURL {
            let workDir = execPath.deletingLastPathComponent()
            let assetsDir = workDir.appendingPathComponent("Assets")

            if FileManager.default.fileExists(atPath: assetsDir.path) {
                addFolder(at: assetsDir)
            }

            let audioDefaultDir = workDir.appendingPathComponent("AudioDefault")
            if FileManager.default.fileExists(atPath: audioDefaultDir.path) {
                addFolder(at: audioDefaultDir)
            }
        }
    }

    func addFolder(at url: URL) {
        let folderName = url.lastPathComponent

        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else { return }

        var audioFiles: [AudioFile] = []

        for fileURL in contents {
            let fileName = fileURL.deletingPathExtension().lastPathComponent
            if fileURL.pathExtension.lowercased() == "mp3" {
                let pattern = "^(\\d{5})$"
                if let range = fileName.range(of: pattern, options: .regularExpression) {
                    let indexStr = String(fileName[range])
                    if let index = Int(indexStr) {
                        let audioFile = AudioFile(name: fileName, url: fileURL, index: index)
                        audioFiles.append(audioFile)
                    }
                }
            }
        }

        audioFiles.sort { $0.index < $1.index }

        if !audioFiles.isEmpty {
            let folder = AudioFolder(name: folderName, url: url, files: audioFiles)
            if !availableFolders.contains(where: { $0.url == url }) {
                availableFolders.append(folder)
                if currentFolder == nil {
                    selectFolder(folder)
                }
            }
        }
    }

    func selectFolder(_ folder: AudioFolder) {
        currentFolder = folder
        availableFiles = folder.files
        if let firstFile = availableFiles.first {
            selectFile(firstFile)
        }
    }

    func selectFile(_ file: AudioFile) {
        currentFile = file
        prepareToPlay(file: file)
    }

    private func prepareToPlay(file: AudioFile) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: file.url)
            audioPlayer?.volume = currentVolume
            audioPlayer?.prepareToPlay()
        } catch {
            print("Failed to load audio: \(error)")
        }
    }

    func togglePlayPause() {
        guard let player = audioPlayer else { return }

        if isPlaying {
            player.pause()
            isPlaying = false
            stopTimer()
        } else {
            player.play()
            isPlaying = true
            startTimer()
        }
    }

    func play() {
        guard let player = audioPlayer else { return }
        player.play()
        isPlaying = true
        startTimer()
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlaying = false
        stopTimer()
    }

    func playRandom() {
        guard !availableFiles.isEmpty else { return }
        let randomFile = availableFiles.randomElement()!
        selectFile(randomFile)
        play()
    }

    func playNext() {
        guard let current = currentFile, !availableFiles.isEmpty else { return }

        if isRandom {
            playRandom()
        } else {
            if let currentIndex = availableFiles.firstIndex(where: { $0.id == current.id }) {
                let nextIndex = (currentIndex + 1) % availableFiles.count
                selectFile(availableFiles[nextIndex])
                if isPlaying {
                    play()
                }
            }
        }
    }

    private func startTimer() {
        playerTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkPlaybackStatus()
        }
    }

    private func stopTimer() {
        playerTimer?.invalidate()
        playerTimer = nil
    }

    private func checkPlaybackStatus() {
        guard let player = audioPlayer else { return }

        if !player.isPlaying && player.currentTime >= player.duration - 0.1 {
            if isLooping {
                if isRandom {
                    playRandom()
                } else {
                    playNext()
                }
            } else {
                isPlaying = false
                stopTimer()
            }
        }
    }

    func removeFolder(_ folder: AudioFolder) {
        availableFolders.removeAll { $0.id == folder.id }
        if currentFolder?.id == folder.id {
            currentFolder = availableFolders.first
            if let newFolder = currentFolder {
                selectFolder(newFolder)
            } else {
                currentFile = nil
                availableFiles = []
                audioPlayer = nil
            }
        }
    }
}
