//
//  ContentView.swift
//  Ciallo
//
//  Created by 星空喵 on 2026/5/1.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var audioManager = AudioManager()
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showingFolderPicker = false
    @State private var securityScopedBookmark: URL?

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebarContent
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 250)
        } detail: {
            detailContent
        }
    }

    private var sidebarContent: some View {
        List {
            folderSection
            if audioManager.currentFolder != nil {
                audioFilesSection
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Ciallo")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                sidebarToggleButton
            }
        }
        .fileImporter(
            isPresented: $showingFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false,
            onCompletion: handleFolderSelection
        )
    }

    private var folderSection: some View {
        Section("文件夹") {
            ForEach(audioManager.availableFolders) { folder in
                FolderRow(
                    folder: folder,
                    isSelected: audioManager.currentFolder?.id == folder.id,
                    onSelect: {
                        audioManager.selectFolder(folder)
                    }
                )
            }

            addFolderButton
        }
    }

    private var audioFilesSection: some View {
        Section("音频文件") {
            ForEach(audioManager.currentFolder?.files ?? []) { file in
                AudioFileRow(
                    file: file,
                    isSelected: audioManager.currentFile?.id == file.id,
                    onSelect: {
                        audioManager.selectFile(file)
                        if !audioManager.isPlaying {
                            audioManager.togglePlayPause()
                        }
                    }
                )
            }
        }
    }

    private var addFolderButton: some View {
        Button(action: { showingFolderPicker = true }) {
            Label("添加文件夹", systemImage: "folder.badge.plus")
        }
        .buttonStyle(.plain)
        .foregroundColor(.accentColor)
    }

    private var sidebarToggleButton: some View {
        Button(action: toggleSidebar) {
            Image(systemName: "sidebar.left")
        }
    }

    private func toggleSidebar() {
        withAnimation {
            columnVisibility = columnVisibility == .all ? .detailOnly : .all
        }
    }

    private func handleFolderSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                audioManager.addFolder(at: url)
            }
        case .failure(let error):
            print("Failed to select folder: \(error)")
        }
    }

    private var detailContent: some View {
        VStack(spacing: 30) {
            Spacer()
            playButton
            volumeControl
            playbackModeControls
            Spacer()
            bottomControls
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var playButton: some View {
        Button(action: { audioManager.togglePlayPause() }) {
            Image(systemName: audioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
        }
        .buttonStyle(.plain)
        .disabled(audioManager.currentFile == nil)
    }

    private var volumeControl: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "speaker.fill")
                    .foregroundColor(.secondary)
                Slider(value: $audioManager.currentVolume, in: 0...1)
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundColor(.secondary)
            }
            .frame(width: 200)

            Text("音量: \(Int(audioManager.currentVolume * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var playbackModeControls: some View {
        VStack(spacing: 16) {
            if let currentFile = audioManager.currentFile {
                Text(currentFile.name)
                    .font(.headline)
                    .lineLimit(1)
            }

            HStack(spacing: 20) {
                previousButton
                shuffleButton
                nextButton
            }
        }
    }

    private var previousButton: some View {
        Button(action: playPrevious) {
            Image(systemName: "backward.fill")
                .font(.title2)
        }
        .buttonStyle(.plain)
        .disabled(audioManager.currentFile == nil || audioManager.isRandom)
    }

    private var shuffleButton: some View {
        Button(action: { audioManager.playRandom() }) {
            Image(systemName: "shuffle")
                .font(.title2)
        }
        .buttonStyle(.plain)
        .disabled(audioManager.availableFiles.isEmpty)
    }

    private var nextButton: some View {
        Button(action: { audioManager.playNext() }) {
            Image(systemName: "forward.fill")
                .font(.title2)
        }
        .buttonStyle(.plain)
        .disabled(audioManager.currentFile == nil || audioManager.isRandom)
    }

    private func playPrevious() {
        guard let folder = audioManager.currentFolder,
              let currentIndex = folder.files.firstIndex(where: { $0.id == audioManager.currentFile?.id }) else { return }
        let prevIndex = (currentIndex - 1 + folder.files.count) % folder.files.count
        audioManager.selectFile(folder.files[prevIndex])
        if audioManager.isPlaying {
            audioManager.play()
        }
    }

    private var bottomControls: some View {
        HStack {
            randomToggle
            loopToggle
        }
        .padding(.horizontal)
    }

    private var randomToggle: some View {
        Toggle(isOn: $audioManager.isRandom) {
            Label("随机播放", systemImage: "shuffle")
        }
        .toggleStyle(.checkbox)
    }

    private var loopToggle: some View {
        Toggle(isOn: $audioManager.isLooping) {
            Label("循环播放", systemImage: "repeat")
        }
        .toggleStyle(.checkbox)
    }
}

struct FolderRow: View {
    let folder: AudioFolder
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        HStack {
            Button(action: onSelect) {
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.blue)
                    Text(folder.name)
                        .foregroundColor(isSelected ? .accentColor : .primary)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Text("\(folder.files.count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct AudioFileRow: View {
    let file: AudioFile
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: "music.note")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                Text(file.name)
                    .foregroundColor(isSelected ? .accentColor : .primary)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
