import SwiftUI
import AVKit

struct TreeGrowthPlayerView: View {
    let treeId: String
    let seed: Int
    let progress: Double // 1.0 (seed/start) to 0.0 (grown/end)
    
    @State private var player: AVPlayer?
    @State private var duration: Double = 0
    
    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .disabled(true)
                    .onAppear {
                        player.play()
                        player.pause()
                    }
            } else {
                Image("\(treeId)_0_grid")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
        .onChange(of: treeId) { oldValue, newValue in loadVideo() }
        .onChange(of: seed) { oldValue, newValue in loadVideo() }
        .onChange(of: progress) { oldValue, newProgress in
            scrubTo(progress: newProgress)
        }
        .onAppear {
            loadVideo()
        }
    }
    
    private func loadVideo() {
        let remoteUrlString = "https://trease-focus.github.io/cache-trees-cdn/video/\(treeId)_\(seed).webm"
        let localPath = "/Users/jatinfoujdar/Downloads/trease-app-master/cache-trees-cdn-cache-data/video/\(treeId)_\(seed).webm"
        
        let url: URL
        if FileManager.default.fileExists(atPath: localPath) {
            url = URL(fileURLWithPath: localPath)
        } else if let remoteUrl = URL(string: remoteUrlString) {
            url = remoteUrl
        } else {
            return
        }
        
        // iOS AVPlayer does not natively support WebM format. Bypass loading to avoid AVFoundation crash/errors.
        if url.pathExtension.lowercased() == "webm" {
            return
        }
        
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        
        Task {
            do {
                let dur = try await asset.load(.duration)
                let durSeconds = CMTimeGetSeconds(dur)
                DispatchQueue.main.async {
                    self.duration = durSeconds
                    self.player = AVPlayer(playerItem: playerItem)
                    self.player?.play()
                    self.player?.pause()
                    self.scrubTo(progress: self.progress)
                }
            } catch {
                print("Failed to load duration for video: \(error)")
            }
        }
    }
    
    private func scrubTo(progress: Double) {
        guard let player = player, duration > 0 else { return }
        let growthPercent = 1.0 - progress
        let targetTimeSeconds = growthPercent * duration
        let targetCMTime = CMTime(seconds: targetTimeSeconds, preferredTimescale: 600)
        
        player.seek(to: targetCMTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
}
