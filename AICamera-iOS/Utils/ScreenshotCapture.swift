import SwiftUI
import AVFoundation

class ScreenshotCapture: ObservableObject {
    private var playerViewRef: VideoPlayerUIView?
    
    func setPlayerView(_ playerView: VideoPlayerUIView) {
        self.playerViewRef = playerView
    }
    
    func captureFrame() -> UIImage? {
        return playerViewRef?.captureFrame()
    }
}

// Coordinator to bridge UIKit and SwiftUI
class VideoPlayerCoordinator: ObservableObject {
    @Published var screenshotCapture = ScreenshotCapture()
    
    func setPlayerView(_ playerView: VideoPlayerUIView) {
        screenshotCapture.setPlayerView(playerView)
    }
}
