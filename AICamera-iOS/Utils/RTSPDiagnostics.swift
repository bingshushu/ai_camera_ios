import Foundation
import SwiftUI

// RTSP连接配置
struct RTSPConfig {
    static let defaultURL = AppConfig.rtspURL
    static let defaultUsername = AppConfig.rtspUsername
    static let defaultPassword = AppConfig.rtspPassword
    
    // 常见的RTSP测试URL（用于调试）
    static let testStreams = [
        AppConfig.rtspURL,  // 你的相机
        "rtsp://wowzaec2demo.streamlock.net/vod/mp4:BigBuckBunny_115k.mp4", // 公共测试流
        "rtsp://demo:demo@ipvmdemo.dyndns.org:5541/onvif-media/media.amp"   // ONVIF测试流
    ]
}

// RTSP连接诊断工具
class RTSPDiagnostics {
    static func checkNetworkConnectivity(to host: String, completion: @escaping (Bool) -> Void) {
        // 简单的网络可达性检查
        guard let url = URL(string: "http://\(host)") else {
            completion(false)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { _, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse {
                    completion(httpResponse.statusCode < 500)
                } else {
                    completion(error == nil)
                }
            }
        }
        task.resume()
    }
    
    static func extractHostFromRTSP(_ rtspURL: String) -> String {
        guard let url = URL(string: rtspURL),
              let host = url.host else {
            return "192.168.1.87" // 默认主机
        }
        return host
    }
    
    static func testRTSPURL(_ rtspURL: String, completion: @escaping (String) -> Void) {
        let host = extractHostFromRTSP(rtspURL)
        
        checkNetworkConnectivity(to: host) { isReachable in
            if isReachable {
                completion("✅ 网络连接正常到 \(host)")
            } else {
                completion("❌ 无法连接到主机 \(host)，请检查：\n• 设备是否在同一网络\n• IP地址是否正确\n• 路由器设置是否阻止连接")
            }
        }
    }
}
