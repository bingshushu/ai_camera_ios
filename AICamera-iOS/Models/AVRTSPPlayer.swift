import Foundation
import AVFoundation
import SwiftUI
import Combine

// 高性能RTSP播放器 - 使用AVPlayer
class AVRTSPPlayer: NSObject, ObservableObject {
    @Published var isConnected = false
    @Published var isLoading = false
    @Published var statusText = "Disconnected"
    @Published var hasStreamIssue = false
    @Published var currentTime: Double = 0
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var statusObservation: NSKeyValueObservation?
    private var playbackObservation: NSKeyValueObservation?
    
    // RTSP Configuration - 使用统一配置
    private let rtspURL = AppConfig.rtspURL
    private let username = AppConfig.rtspUsername
    private let password = AppConfig.rtspPassword
    
    override init() {
        super.init()
        setupPlayer()
    }
    
    deinit {
        cleanup()
    }
    
    private func setupPlayer() {
        // 创建AVPlayer实例
        player = AVPlayer()
        
        // 优化AVPlayer配置
        player?.automaticallyWaitsToMinimizeStalling = false
        player?.playImmediately(atRate: 1.0)
        
        // 开始连接
        connect()
    }
    
    func connect() {
        DispatchQueue.main.async {
            self.isLoading = true
            self.statusText = "Connecting..."
            self.hasStreamIssue = false
        }
        
        let authenticatedURL = createAuthenticatedURL()
        print("🔗 AVPlayer connecting to: \(authenticatedURL)")
        
        guard let url = URL(string: authenticatedURL) else {
            DispatchQueue.main.async {
                self.statusText = "Invalid URL"
                self.hasStreamIssue = true
                self.isLoading = false
            }
            return
        }
        
        // 创建AVPlayerItem with optimized settings
        setupPlayerItem(with: url)
    }
    
    private func setupPlayerItem(with url: URL) {
        // 清理之前的item
        cleanupPlayerItem()
        
        // 创建新的player item
        playerItem = AVPlayerItem(url: url)
        
        // 配置播放器项目
        configurePlayerItem()
        
        // 设置到播放器
        player?.replaceCurrentItem(with: playerItem)
        
        // 开始播放
        player?.play()
        
        // 添加观察者
        addObservers()
    }
    
    private func configurePlayerItem() {
        guard let item = playerItem else { return }
        
        // 配置缓冲策略 - 优化实时流播放
        item.preferredForwardBufferDuration = 1.0  // 减少缓冲时间
        item.canUseNetworkResourcesForLiveStreamingWhilePaused = false
        
        // 设置音视频处理选项
        if #available(iOS 13.0, *) {
            item.preferredMaximumResolution = CGSize(width: 1920, height: 1080)
        }
    }
    
    private func addObservers() {
        guard let item = playerItem else { return }
        
        // 监听播放状态
        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                self?.handleStatusChange(item.status)
            }
        }
        
        // 监听缓冲状态
        playbackObservation = item.observe(\.isPlaybackBufferEmpty, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                if item.isPlaybackBufferEmpty {
                    self?.statusText = "Buffering..."
                } else if self?.isConnected == true {
                    self?.statusText = "Playing"
                }
            }
        }
        
        // 监听播放时间
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }
        
        // 监听播放结束
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.handlePlaybackEnded()
        }
        
        // 监听播放失败
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] notification in
            self?.handlePlaybackFailed(notification)
        }
    }
    
    private func handleStatusChange(_ status: AVPlayerItem.Status) {
        switch status {
        case .unknown:
            statusText = "Initializing..."
            isLoading = true
            print("📱 AVPlayer: Unknown status")
            
        case .readyToPlay:
            statusText = "Playing"
            isConnected = true
            isLoading = false
            hasStreamIssue = false
            print("✅ AVPlayer: Ready to play")
            
        case .failed:
            if let error = playerItem?.error {
                statusText = "Connection failed"
                print("❌ AVPlayer failed: \(error.localizedDescription)")
            } else {
                statusText = "Unknown error"
            }
            isConnected = false
            isLoading = false
            hasStreamIssue = true
            
        @unknown default:
            statusText = "Unknown state"
            isLoading = false
        }
    }
    
    private func handlePlaybackEnded() {
        print("🔚 AVPlayer: Playback ended")
        statusText = "Stream ended"
        isConnected = false
        hasStreamIssue = true
    }
    
    private func handlePlaybackFailed(_ notification: Notification) {
        if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
            print("❌ AVPlayer playback failed: \(error.localizedDescription)")
            statusText = "Playback failed"
        } else {
            statusText = "Unknown playback error"
        }
        isConnected = false
        hasStreamIssue = true
    }
    
    private func createAuthenticatedURL() -> String {
        if username.isEmpty && password.isEmpty {
            return rtspURL
        } else {
            // Parse URL and add authentication
            var components = URLComponents(string: rtspURL)
            components?.user = username
            components?.password = password
            return components?.url?.absoluteString ?? rtspURL
        }
    }
    
    func disconnect() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.statusText = "Disconnected"
            self.isLoading = false
            self.hasStreamIssue = false
        }
    }
    
    func retry() {
        print("🔄 AVPlayer: Retrying connection...")
        disconnect()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.connect()
        }
    }
    
    // 获取AVPlayer实例用于SwiftUI
    func getAVPlayer() -> AVPlayer? {
        return player
    }
    
    private func cleanupPlayerItem() {
        statusObservation?.invalidate()
        playbackObservation?.invalidate()
        
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemFailedToPlayToEndTime, object: playerItem)
        
        playerItem = nil
    }
    
    private func cleanup() {
        cleanupPlayerItem()
        player?.pause()
        player = nil
    }
}
