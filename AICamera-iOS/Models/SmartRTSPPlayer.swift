import Foundation
import AVFoundation
import SwiftUI
import Combine

// 智能RTSP播放器 - 自动选择最优播放方案
class SmartRTSPPlayer: NSObject, ObservableObject {
    @Published var isConnected = false
    @Published var isLoading = false
    @Published var statusText = "Disconnected"
    @Published var hasStreamIssue = false
    @Published var playerType = "None"
    
    // 播放器实例
    private var avPlayer: AVPlayer?
    private var hlsStreamURL: String?
    
    // RTSP Configuration
    private let rtspURL = AppConfig.rtspURL
    private let username = AppConfig.rtspUsername
    private let password = AppConfig.rtspPassword
    
    override init() {
        super.init()
        connect()
    }
    
    func connect() {
        DispatchQueue.main.async {
            self.isLoading = true
            self.statusText = "尝试连接方案..."
            self.hasStreamIssue = false
        }
        
        // 策略1: 尝试RTSP over HTTP (某些相机支持)
        tryRTSPOverHTTP()
    }
    
    private func tryRTSPOverHTTP() {
        // 许多IP相机支持通过HTTP端口获取RTSP流
        let httpStreamURL = convertRTSPToHTTP(rtspURL)
        print("🔄 尝试HTTP流: \(httpStreamURL)")
        
        setupAVPlayer(with: httpStreamURL, type: "HTTP-MJPEG") { [weak self] success in
            if !success {
                self?.tryDirectRTSP()
            }
        }
    }
    
    private func tryDirectRTSP() {
        // 某些iOS版本和配置可能支持RTSP
        print("🔄 尝试直接RTSP连接")
        let authenticatedURL = createAuthenticatedURL()
        
        setupAVPlayer(with: authenticatedURL, type: "RTSP") { [weak self] success in
            if !success {
                self?.tryHLSConversion()
            }
        }
    }
    
    private func tryHLSConversion() {
        // 如果有HLS转换服务，使用HLS
        print("🔄 尝试HLS转换")
        
        DispatchQueue.main.async {
            self.statusText = "RTSP需要额外配置"
            self.hasStreamIssue = true
            self.isLoading = false
            self.playerType = "需要HLS转换"
        }
        
        // 提供解决方案提示
        showRTSPSolution()
    }
    
    private func setupAVPlayer(with urlString: String, type: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        // 创建AVPlayer
        avPlayer = AVPlayer(url: url)
        avPlayer?.automaticallyWaitsToMinimizeStalling = false
        
        // 监听播放状态
        let playerItem = AVPlayerItem(url: url)
        avPlayer?.replaceCurrentItem(with: playerItem)
        
        // 添加状态观察者
        let observation = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    self?.statusText = "播放中 (\(type))"
                    self?.isConnected = true
                    self?.isLoading = false
                    self?.hasStreamIssue = false
                    self?.playerType = type
                    self?.avPlayer?.play()
                    completion(true)
                    
                case .failed:
                    if let error = item.error {
                        print("❌ \(type) 播放失败: \(error.localizedDescription)")
                    }
                    completion(false)
                    
                case .unknown:
                    break
                    
                @unknown default:
                    completion(false)
                }
            }
        }
        
        // 延迟检查（给播放器一些时间尝试连接）
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if playerItem.status == .unknown || playerItem.status == .failed {
                observation.invalidate()
                completion(false)
            }
        }
    }
    
    private func convertRTSPToHTTP(_ rtspURL: String) -> String {
        // 将RTSP URL转换为可能的HTTP MJPEG流URL
        // 这取决于具体的相机品牌和型号
        
        var httpURL = rtspURL
        httpURL = httpURL.replacingOccurrences(of: "rtsp://", with: "http://")
        
        // 常见的IP相机HTTP流路径
        let commonPaths = [
            "/video.cgi",
            "/mjpeg.cgi", 
            "/video.mjpg",
            "/live.mjpg",
            "/snapshot.cgi",
            "/axis-cgi/mjpg/video.cgi",
            "/cgi-bin/mjpeg"
        ]
        
        // 对于我们的相机，尝试常见路径
        if httpURL.contains("192.168.1.87") {
            // 移除端口和路径，添加可能的HTTP流路径
            let baseURL = "http://\(username):\(password)@192.168.1.87"
            return "\(baseURL)/mjpeg.cgi"  // 常见的MJPEG路径
        }
        
        return httpURL
    }
    
    private func createAuthenticatedURL() -> String {
        if username.isEmpty && password.isEmpty {
            return rtspURL
        } else {
            var components = URLComponents(string: rtspURL)
            components?.user = username
            components?.password = password
            return components?.url?.absoluteString ?? rtspURL
        }
    }
    
    private func showRTSPSolution() {
        print("""
        📋 RTSP播放解决方案:
        
        1. 【推荐】使用HTTP MJPEG流:
           - 大多数IP相机支持HTTP MJPEG
           - URL格式: http://admin:admin@192.168.1.87/mjpeg.cgi
           
        2. 使用HLS转换服务:
           - 部署FFmpeg转换服务器
           - 将RTSP转为HLS格式
           
        3. 使用专门的RTSP库:
           - 如果必须使用RTSP，考虑IJKPlayer或FFmpeg
           
        4. 检查相机设置:
           - 确认相机是否支持HTTP流输出
           - 查看相机管理页面的流配置
        """)
    }
    
    func disconnect() {
        avPlayer?.pause()
        avPlayer?.replaceCurrentItem(with: nil)
        avPlayer = nil
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.statusText = "已断开"
            self.isLoading = false
            self.hasStreamIssue = false
            self.playerType = "None"
        }
    }
    
    func retry() {
        print("🔄 重试智能连接...")
        disconnect()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.connect()
        }
    }
    
    func getAVPlayer() -> AVPlayer? {
        return avPlayer
    }
}