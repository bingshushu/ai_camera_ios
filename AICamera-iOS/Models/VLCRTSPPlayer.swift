import SwiftUI
import MobileVLCKit
import Combine
import Foundation

class VLCRTSPPlayer: NSObject, ObservableObject {
    @Published var isConnected = false
    @Published var isLoading = false
    @Published var statusText = "Disconnected"
    @Published var hasStreamIssue = false
    
    private var mediaPlayer: VLCMediaPlayer?
    private var media: VLCMedia?
    
    // RTSP Configuration - 使用统一配置
    private let defaultRTSPURL = AppConfig.rtspURL
    private let defaultUsername = AppConfig.rtspUsername
    private let defaultPassword = AppConfig.rtspPassword
    
    override init() {
        super.init()
        setupPlayer()
    }
    
    deinit {
        cleanup()
    }
    
    private func setupPlayer() {
        // Create VLC media player
        mediaPlayer = VLCMediaPlayer()
        mediaPlayer?.delegate = self
        
        // Configure VLC options for RTSP
        setupVLCOptions()
        
        // Start connection
        connect()
    }
    
    private func setupVLCOptions() {
        guard let player = mediaPlayer else { return }
        
        print("🔧 配置VLC选项...")
        
        // Configure VLC options for stable RTSP streaming
        let options = [
            "--verbose=0",                   // Reduce logging
            "--intf=dummy",                  // No interface
            "--extraintf=",                  // No extra interfaces
            "--network-caching=300",         // Network cache in ms
            "--rtsp-tcp",                   // Force TCP for RTSP (more reliable)
            "--rtsp-timeout=10",            // RTSP timeout (increased)
            "--live-caching=300",           // Live stream caching
            "--sout-keep",                  // Keep stream output
            "--no-audio",                   // Disable audio for now (focus on video)
            "--vout=ios_eagl",              // iOS video output
            "--avcodec-hw=any",             // Hardware acceleration
            "--avcodec-threads=4",          // Multi-threading
            "--no-stats",                   // Disable statistics
            "--no-osd",                     // No on-screen display
            "--clock-jitter=0",             // Reduce jitter
            "--clock-synchro=0",            // Reduce sync issues
            "--rtsp-mcast-timeout=5"        // Multicast timeout
        ]
        
        // Print options for debugging
        for option in options {
            print("VLC option: \(option)")
        }
        
        print("✅ VLC选项配置完成")
    }
    
    private func createAuthenticatedURL() -> String {
        if defaultUsername.isEmpty && defaultPassword.isEmpty {
            return defaultRTSPURL
        } else {
            // Parse URL and add authentication
            var components = URLComponents(string: defaultRTSPURL)
            components?.user = defaultUsername
            components?.password = defaultPassword
            return components?.url?.absoluteString ?? defaultRTSPURL
        }
    }
    
    func connect() {
        DispatchQueue.main.async {
            self.isLoading = true
            self.statusText = "Connecting..."
            self.hasStreamIssue = false
        }
        
        let rtspURL = createAuthenticatedURL()
        print("🔗 Connecting to RTSP URL: \(rtspURL)")
        
        // Create media with RTSP URL
        guard let url = URL(string: rtspURL) else {
            print("❌ Invalid RTSP URL: \(rtspURL)")
            DispatchQueue.main.async {
                self.statusText = "Invalid URL"
                self.hasStreamIssue = true
                self.isLoading = false
            }
            return
        }
        
        media = VLCMedia(url: url)
        
        // Apply VLC options to media
        setupMediaOptions()
        
        // Set media to player
        mediaPlayer?.media = media
        
        // Start playing
        print("▶️ Starting VLC media player...")
        mediaPlayer?.play()
    }
    
    private func setupMediaOptions() {
        guard let media = media else { return }
        
        // Critical options for RTSP streaming
        let mediaOptions = [
            ":network-caching=300",          // Network cache in ms
            ":rtsp-tcp",                     // Force TCP transport
            ":rtsp-timeout=5",               // Connection timeout
            ":live-caching=300",             // Live stream cache
            ":avcodec-hw=any",               // Hardware decoding
            ":avcodec-threads=4",            // Multi-threaded decoding
            ":clock-jitter=0",               // Reduce clock jitter
            ":clock-synchro=0",              // Disable clock sync
            ":no-audio",                     // Disable audio for now
            ":rtsp-frame-buffer-size=500000" // Increase frame buffer
        ]
        
        // Add each option to the media
        for option in mediaOptions {
            media.addOption(option)
            print("Media option added: \(option)")
        }
    }
    
    func disconnect() {
        mediaPlayer?.stop()
        DispatchQueue.main.async {
            self.isConnected = false
            self.statusText = "Disconnected"
            self.isLoading = false
            self.hasStreamIssue = false
        }
    }
    
    func retry() {
        disconnect()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.connect()
        }
    }
    
    func captureCurrentFrame() -> UIImage? {
        guard let player = mediaPlayer, player.isPlaying else {
            return nil
        }
        
        // VLC doesn't provide direct frame capture like AVPlayer
        // This would require more complex implementation using VLC's snapshot functionality
        // For now, return nil - this can be implemented later if needed
        return nil
    }
    
    // Get the VLC media player for use in SwiftUI view
    func getMediaPlayer() -> VLCMediaPlayer? {
        return mediaPlayer
    }
    
    private func cleanup() {
        mediaPlayer?.stop()
        mediaPlayer?.delegate = nil
        mediaPlayer = nil
        media = nil
    }
}

// MARK: - VLCMediaPlayerDelegate
extension VLCRTSPPlayer: VLCMediaPlayerDelegate {
    func mediaPlayerStateChanged(_ aNotification: Notification?) {
        guard let player = mediaPlayer else { return }
        
        let currentState = player.state
        print("🎬 VLC Player state changed to: \(stateString(currentState))")
        
        DispatchQueue.main.async {
            switch currentState {
            case .stopped:
                self.statusText = "Stopped"
                self.isConnected = false
                self.isLoading = false
                print("⏹️ Player stopped")
                
            case .opening:
                self.statusText = "Opening stream..."
                self.isLoading = true
                self.isConnected = false
                self.hasStreamIssue = false
                print("📂 Opening stream...")
                
            case .buffering:
                self.statusText = "Buffering..."
                self.isLoading = true
                self.isConnected = false
                print("⏳ Buffering stream...")
                
            case .playing:
                self.statusText = "Playing"
                self.isConnected = true
                self.isLoading = false
                self.hasStreamIssue = false
                print("▶️ Stream playing successfully!")
                
            case .paused:
                self.statusText = "Paused"
                self.isLoading = false
                print("⏸️ Stream paused")
                
            case .ended:
                self.statusText = "Stream ended"
                self.isConnected = false
                self.isLoading = false
                print("🔚 Stream ended")
                
            case .error:
                self.statusText = "Connection error"
                self.isConnected = false
                self.isLoading = false
                self.hasStreamIssue = true
                print("❌ Player error occurred")
                
            case .esAdded:
                print("📺 Elementary stream added")
                break // Elementary stream added
                
            @unknown default:
                self.statusText = "Unknown state"
                self.isLoading = false
                self.isConnected = false
                print("❓ Unknown player state: \(currentState.rawValue)")
            }
        }
    }
    
    private func stateString(_ state: VLCMediaPlayerState) -> String {
        switch state {
        case .stopped: return "Stopped"
        case .opening: return "Opening"
        case .buffering: return "Buffering"
        case .playing: return "Playing"
        case .paused: return "Paused"
        case .ended: return "Ended"
        case .error: return "Error"
        case .esAdded: return "ES Added"
        @unknown default: return "Unknown(\(state.rawValue))"
        }
    }
    
    func mediaPlayerTimeChanged(_ aNotification: Notification?) {
        // Handle time changes if needed
        // This is called periodically during playback
    }
}
