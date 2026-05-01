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
    @State private var showingFolderPicker = false

    var body: some View {
        NavigationSplitView {
            List {
                Section("音频文件") {
                    ForEach(audioManager.files) { file in
                        AudioFileRow(
                            file: file,
                            isSelected: audioManager.currentFile?.id == file.id,
                            onSelect: {
                                audioManager.selectFile(file)
                                audioManager.togglePlayPause()
                            }
                        )
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Ciallo")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button("添加文件夹") {
                        showingFolderPicker = true
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFolderPicker,
                allowedContentTypes: [.folder],
                allowsMultipleSelection: false,
                onCompletion: handleFolderSelection
            )
            .onAppear {
                loadDefaultFolder()
            }
        } detail: {
            detailContent
        }
    }

    private func loadDefaultFolder() {
        if let resourcesURL = Bundle.main.resourceURL {
            audioManager.loadFiles(from: resourcesURL)
        }
    }

    private func handleFolderSelection(result: Result<[URL], Error>) {
        if case .success(let urls) = result, let url = urls.first {
            audioManager.loadFiles(from: url)
        }
    }

    private var detailContent: some View {
        VStack(spacing: 30) {
            Spacer()

            playButton

            volumeControl

            currentFileName

            playbackControls

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
        HStack {
            Image(systemName: "speaker.fill")
            Slider(value: $audioManager.currentVolume, in: 0...1, onEditingChanged: { editing in
                if !editing {
                    audioManager.setVolume(audioManager.currentVolume)
                }
            })
            Image(systemName: "speaker.wave.3.fill")
        }
        .frame(width: 200)
    }

    private var currentFileName: some View {
        Text(audioManager.currentFile?.name ?? "未选择音频")
            .font(.headline)
    }

    private var playbackControls: some View {
        HStack(spacing: 30) {
            Button(action: { audioManager.playRandom() }) {
                Image(systemName: "shuffle")
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .disabled(audioManager.files.isEmpty)

            Button(action: { audioManager.playNext() }) {
                Image(systemName: "forward.fill")
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .disabled(audioManager.currentFile == nil)
        }
    }

    private var bottomControls: some View {
        HStack {
            Toggle("随机播放", isOn: $audioManager.isRandom)
            Toggle("循环播放", isOn: $audioManager.isLooping)
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
