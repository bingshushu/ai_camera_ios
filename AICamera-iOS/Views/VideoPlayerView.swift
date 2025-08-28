import SwiftUI
import AVFoundation

struct VideoPlayerView: UIViewRepresentable {
    let player: AVPlayer
    @Binding var videoSize: CGSize
    let coordinator: VideoPlayerCoordinator
    
    func makeUIView(context: Context) -> VideoPlayerUIView {
        let view = VideoPlayerUIView()
        view.player = player
        view.onSizeChanged = { size in
            DispatchQueue.main.async {
                videoSize = size
            }
        }
        coordinator.setPlayerView(view)
        return view
    }
    
    func updateUIView(_ uiView: VideoPlayerUIView, context: Context) {
        uiView.player = player
        coordinator.setPlayerView(uiView)
    }
}

class VideoPlayerUIView: UIView {
    var player: AVPlayer? {
        didSet {
            playerLayer.player = player
        }
    }
    
    var onSizeChanged: ((CGSize) -> Void)?
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Configure player layer
        playerLayer.videoGravity = .resizeAspect
        
        // Notify size changes
        let videoRect = playerLayer.videoRect
        if !videoRect.isEmpty {
            onSizeChanged?(videoRect.size)
        }
    }
    
    func captureFrame() -> UIImage? {
        guard let player = player,
              let currentItem = player.currentItem,
              currentItem.status == .readyToPlay else {
            return nil
        }
        
        let videoOutput = AVPlayerItemVideoOutput()
        currentItem.add(videoOutput)
        
        let currentTime = currentItem.currentTime()
        
        if videoOutput.hasNewPixelBuffer(forItemTime: currentTime) {
            let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: nil)
            if let buffer = pixelBuffer {
                let ciImage = CIImage(cvPixelBuffer: buffer)
                let context = CIContext()
                if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                    return UIImage(cgImage: cgImage)
                }
            }
        }
        
        currentItem.remove(videoOutput)
        return nil
    }
}
