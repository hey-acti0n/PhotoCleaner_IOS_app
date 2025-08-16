import SwiftUI
import AVKit
import Photos

struct VideoPlayerView: View {
    let asset: PHAsset
    let photoManager: PhotoManager
    @State private var playerItem: AVPlayerItem?
    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .aspectRatio(contentMode: .fit)
                    .onAppear {
                        // Автоматически запускаем воспроизведение
                        player.play()
                    }
                    .onDisappear {
                        // Останавливаем воспроизведение при исчезновении
                        player.pause()
                    }
            } else if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .foregroundColor(.white)
                    
                    Text("Загрузка видео...")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            } else if let errorMessage = errorMessage {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("Loading error")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            // Индикатор типа медиафайла
            VStack {
                HStack {
                    HStack {
                        Image(systemName: "video.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text(getVideoDuration())
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                Spacer()
            }
        }
        .onAppear {
            loadVideo()
        }
        .onDisappear {
            // Очищаем ресурсы при исчезновении
            cleanupPlayer()
        }
    }
    
    private func getVideoDuration() -> String {
        // Безопасное получение длительности видео
        let duration = asset.duration
        if duration.isFinite && !duration.isNaN {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "0:00"
        }
    }
    
    private func loadVideo() {
        isLoading = true
        errorMessage = nil
        
        // Очищаем предыдущий плеер
        cleanupPlayer()
        
        photoManager.getVideoPlayerItem(for: asset) { playerItem in
            DispatchQueue.main.async {
                self.isLoading = false
                if let playerItem = playerItem {
                    self.playerItem = playerItem
                    self.player = AVPlayer(playerItem: playerItem)
                } else {
                    self.errorMessage = "Unable to load the video"
                }
            }
        }
    }
    
    private func cleanupPlayer() {
        player?.pause()
        player = nil
        playerItem = nil
    }
}
