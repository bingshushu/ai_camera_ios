import Foundation

struct AppConfig {
    // RTSP Configuration
    static let rtspURL = "rtsp://192.168.1.87/11"
    static let rtspUsername = "admin"
    static let rtspPassword = "admin"
    
    // Detection Configuration
    static let confidenceThreshold: Float = 0.1
    static let nmsThreshold: Float = 0.48
    static let modelInputSize = 320
    
    // UI Configuration
    static let maxZoomScale: CGFloat = 3.0
    static let minZoomScale: CGFloat = 1.0
    static let aspectRatio: CGFloat = 16.0 / 9.0
    
    // Class Names
    static let classNames = ["ROI", "RedCenter"]
    
    // Colors for detection overlay
    static let roiColor = "green"
    static let redCenterColor = "red"
}
