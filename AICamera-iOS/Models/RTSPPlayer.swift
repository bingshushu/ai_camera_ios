import SwiftUI
import AVFoundation
import Combine

class RTSPPlayer: ObservableObject {
    @Published var player: AVPlayer?
    @Published var isConnected = false
    @Published var isLoading = false
    @Published var statusText = "Disconnected"
    @Published var hasStreamIssue = false
    
    private var playerItem: AVPlayerItem?
    private var statusObserver: AnyCancellable?
    private var timeObserver: Any?
    
    // RTSP Configuration
    private let defaultRTSPURL = "rtsp://192.168.1.88/11"
    private let defaultUsername = "admin"
    private let defaultPassword = "admin"
    
    init() {
        setupPlayer()
    }
    
    deinit {
        cleanup()
    }
    
    private func setupPlayer() {
        // Create RTSP URL with authentication
        guard let url = createAuthenticatedURL() else {
            statusText = "Invalid RTSP URL"
            hasStreamIssue = true
            return
        }
        
        // Create player item
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // Setup observers
        setupObservers()
        
        // Start connection
        connect()
    }
    
    private func createAuthenticatedURL() -> URL? {
        var components = URLComponents(string: defaultRTSPURL)
        components?.user = defaultUsername
        components?.password = defaultPassword
        return components?.url
    }
    
    private func setupObservers() {
        guard let playerItem = playerItem else { return }
        
        // Status observer
        statusObserver = playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.handleStatusChange(status)
            }
        
        // Add time observer for connection monitoring
        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1.0, preferredTimescale: 1),
            queue: .main
        ) { [weak self] _ in
            self?.checkPlaybackStatus()
        }
    }
    
    private func handleStatusChange(_ status: AVPlayerItem.Status) {
        switch status {
        case .unknown:
            statusText = "Connecting..."
            isLoading = true
            isConnected = false
            
        case .readyToPlay:
            statusText = "Connected"
            isLoading = false
            isConnected = true
            hasStreamIssue = false
            player?.play()
            
        case .failed:
            if let error = playerItem?.error {
                statusText = "Error: \(error.localizedDescription)"
            } else {
                statusText = "Connection Failed"
            }
            isLoading = false
            isConnected = false
            hasStreamIssue = true
            
        @unknown default:
            statusText = "Unknown Status"
            isLoading = false
            isConnected = false
        }
    }
    
    private func checkPlaybackStatus() {
        guard let player = player else { return }
        
        if player.rate > 0 && !player.currentTime().isIndefinite {
            if statusText != "Playing" {
                statusText = "Playing"
                hasStreamIssue = false
            }
        }
    }
    
    func connect() {
        isLoading = true
        statusText = "Connecting..."
        hasStreamIssue = false
        
        // Reset player if needed
        if let currentItem = player?.currentItem {
            player?.replaceCurrentItem(with: nil)
        }
        
        // Create new player item and start
        guard let url = createAuthenticatedURL() else {
            statusText = "Invalid RTSP URL"
            hasStreamIssue = true
            isLoading = false
            return
        }
        
        playerItem = AVPlayerItem(url: url)
        player?.replaceCurrentItem(with: playerItem)
        setupObservers()
    }
    
    func disconnect() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        isConnected = false
        statusText = "Disconnected"
        isLoading = false
        hasStreamIssue = false
    }
    
    func retry() {
        disconnect()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.connect()
        }
    }
    
    private func cleanup() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        statusObserver?.cancel()
        player?.pause()
        player = nil
    }
}
