import SwiftUI
import AVFoundation

struct AVVideoPlayerView: UIViewRepresentable {
    let player: AVPlayer?
    @Binding var videoSize: CGSize
    let coordinator: VideoPlayerCoordinator
    
    func makeUIView(context: Context) -> AVVideoPlayerUIView {
        let view = AVVideoPlayerUIView()
        view.setPlayer(player)
        view.onSizeChanged = { size in
            DispatchQueue.main.async {
                videoSize = size
            }
        }
        coordinator.screenshotCapture.setAVPlayerView(view)
        return view
    }
    
    func updateUIView(_ uiView: AVVideoPlayerUIView, context: Context) {
        uiView.setPlayer(player)
        coordinator.screenshotCapture.setAVPlayerView(uiView)
    }
}

class AVVideoPlayerUIView: UIView {
    private var playerLayer: AVPlayerLayer?
    var onSizeChanged: ((CGSize) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .black
        
        // 创建播放器层
        playerLayer = AVPlayerLayer()
        playerLayer?.videoGravity = .resizeAspect  // 保持宽高比
        playerLayer?.backgroundColor = UIColor.black.cgColor
        
        if let layer = playerLayer {
            self.layer.addSublayer(layer)
        }
        
        print("🖥️ AVPlayer: Video view setup complete")
    }
    
    func setPlayer(_ player: AVPlayer?) {
        print("📱 AVPlayer: Setting player to view")
        playerLayer?.player = player
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 更新播放器层框架
        playerLayer?.frame = bounds
        
        // 通知尺寸变化
        DispatchQueue.main.async {
            self.onSizeChanged?(self.bounds.size)
        }
    }
    
    // 截图功能 - 现代实现
    func captureFrame() -> UIImage? {
        guard let player = playerLayer?.player,
              let currentItem = player.currentItem else {
            print("❌ AVPlayer: No player or current item for capture")
            return nil
        }
        
        let imageGenerator = AVAssetImageGenerator(asset: currentItem.asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero
        
        // 使用信号量实现同步等待异步结果
        let semaphore = DispatchSemaphore(value: 0)
        var capturedImage: UIImage?
        
        if #available(iOS 18.0, *) {
            // iOS 18+ 使用新的异步API
            imageGenerator.generateCGImageAsynchronously(for: player.currentTime()) { cgImage, actualTime, error in
                if let cgImage = cgImage {
                    capturedImage = UIImage(cgImage: cgImage)
                    print("✅ AVPlayer: Frame captured successfully (async)")
                } else if let error = error {
                    print("❌ AVPlayer: Frame capture failed (async) - \(error.localizedDescription)")
                }
                semaphore.signal()
            }
            
            // 等待异步操作完成（最多1秒）
            _ = semaphore.wait(timeout: .now() + 1.0)
        } else {
            // iOS 17及以下使用同步API
            do {
                let cgImage = try imageGenerator.copyCGImage(at: player.currentTime(), actualTime: nil)
                capturedImage = UIImage(cgImage: cgImage)
                print("✅ AVPlayer: Frame captured successfully (sync)")
            } catch {
                print("❌ AVPlayer: Frame capture failed (sync) - \(error.localizedDescription)")
            }
        }
        
        return capturedImage
    }
    
    // 获取播放器层用于其他操作
    func getPlayerLayer() -> AVPlayerLayer? {
        return playerLayer
    }
}