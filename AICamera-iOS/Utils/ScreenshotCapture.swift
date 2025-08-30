import SwiftUI
import AVFoundation
import MobileVLCKit

class ScreenshotCapture: ObservableObject {
    private var playerViewRef: VideoPlayerUIView?
    private var vlcPlayerViewRef: VLCVideoPlayerUIView?
    private var avPlayerViewRef: AVVideoPlayerUIView?
    
    func setPlayerView(_ playerView: VideoPlayerUIView) {
        self.playerViewRef = playerView
        self.vlcPlayerViewRef = nil
        self.avPlayerViewRef = nil
    }
    
    func setVLCPlayerView(_ playerView: VLCVideoPlayerUIView) {
        self.vlcPlayerViewRef = playerView
        self.playerViewRef = nil
        self.avPlayerViewRef = nil
    }
    
    func setAVPlayerView(_ playerView: AVVideoPlayerUIView) {
        self.avPlayerViewRef = playerView
        self.playerViewRef = nil
        self.vlcPlayerViewRef = nil
    }
    
    func captureFrame() -> UIImage? {
        if let avView = avPlayerViewRef {
            return avView.captureFrame()
        } else if let vlcView = vlcPlayerViewRef {
            return vlcView.captureFrame()
        } else if let playerView = playerViewRef {
            return playerView.captureFrame()
        }
        return nil
    }
}

// Coordinator to bridge UIKit and SwiftUI
class VideoPlayerCoordinator: ObservableObject {
    @Published var screenshotCapture = ScreenshotCapture()
    
    func setPlayerView(_ playerView: VideoPlayerUIView) {
        screenshotCapture.setPlayerView(playerView)
    }
    
    func setVLCPlayerView(_ playerView: VLCVideoPlayerUIView) {
        screenshotCapture.setVLCPlayerView(playerView)
    }
    
    func setAVPlayerView(_ playerView: AVVideoPlayerUIView) {
        screenshotCapture.setAVPlayerView(playerView)
    }
}
