import SwiftUI
import MobileVLCKit

struct VLCVideoPlayerView: UIViewRepresentable {
    let mediaPlayer: VLCMediaPlayer?
    @Binding var videoSize: CGSize
    let coordinator: VideoPlayerCoordinator
    
    func makeUIView(context: Context) -> VLCVideoPlayerUIView {
        let view = VLCVideoPlayerUIView()
        view.mediaPlayer = mediaPlayer
        view.onSizeChanged = { size in
            DispatchQueue.main.async {
                videoSize = size
            }
        }
        coordinator.screenshotCapture.setVLCPlayerView(view)
        return view
    }
    
    func updateUIView(_ uiView: VLCVideoPlayerUIView, context: Context) {
        uiView.mediaPlayer = mediaPlayer
        coordinator.screenshotCapture.setVLCPlayerView(uiView)
    }
}

class VLCVideoPlayerUIView: UIView {
    var mediaPlayer: VLCMediaPlayer? {
        didSet {
            setupPlayer()
        }
    }
    
    var onSizeChanged: ((CGSize) -> Void)?
    private var vlcVideoView: UIView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .black
    }
    
    private func setupPlayer() {
        print("🎬 VLC: Setting up player view...")
        
        // Remove any existing video view
        vlcVideoView?.removeFromSuperview()
        
        guard let player = mediaPlayer else {
            print("❌ VLC: No media player available")
            return
        }
        
        print("📱 VLC: Creating video output view...")
        
        // Create a new view for VLC video output
        vlcVideoView = UIView()
        vlcVideoView?.backgroundColor = .black
        vlcVideoView?.contentMode = .scaleAspectFit
        
        if let videoView = vlcVideoView {
            addSubview(videoView)
            videoView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                videoView.topAnchor.constraint(equalTo: topAnchor),
                videoView.leadingAnchor.constraint(equalTo: leadingAnchor),
                videoView.trailingAnchor.constraint(equalTo: trailingAnchor),
                videoView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
            
            print("🖥️ VLC: Setting drawable view...")
            // Set the drawable (video output view) for VLC
            player.drawable = videoView
            
            print("✅ VLC: Player view setup complete")
        } else {
            print("❌ VLC: Failed to create video view")
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update video size when layout changes
        DispatchQueue.main.async {
            self.onSizeChanged?(self.bounds.size)
        }
    }
    
    func captureFrame() -> UIImage? {
        // VLC frame capture is more complex and requires different approach
        // This is a placeholder implementation
        guard let player = mediaPlayer, player.isPlaying else {
            return nil
        }
        
        // Create a snapshot using VLC's snapshot functionality
        // Note: This is asynchronous in VLC, so immediate capture isn't straightforward
        // For now, return nil - would need to implement async snapshot callback
        return nil
    }
}

