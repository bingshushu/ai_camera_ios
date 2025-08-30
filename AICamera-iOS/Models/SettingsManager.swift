import Foundation
import SwiftUI

// MARK: - Enums
enum CircleCenterStyle: String, CaseIterable {
    case dot = "DOT"
    case smallCross = "SMALL_CROSS"  
    case largeCross = "LARGE_CROSS"
    case smallCircle = "SMALL_CIRCLE"
    case crossWithCircle = "CROSS_WITH_CIRCLE"
    
    var displayName: String {
        switch self {
        case .dot: return "点"
        case .smallCross: return "小十字"
        case .largeCross: return "大十字"
        case .smallCircle: return "小圆圈"
        case .crossWithCircle: return "十字加圆圈"
        }
    }
}

enum AppLanguage: String, CaseIterable {
    case system = "system"
    case chinese = "zh"
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case arabic = "ar"
    case russian = "ru"
    case german = "de"
    case portuguese = "pt"
    case italian = "it"
    
    var displayName: String {
        switch self {
        case .system: return "跟随系统"
        case .chinese: return "简体中文"
        case .english: return "English"
        case .spanish: return "Español"
        case .french: return "Français"
        case .arabic: return "العربية"
        case .russian: return "Русский"
        case .german: return "Deutsch"
        case .portuguese: return "Português"
        case .italian: return "Italiano"
        }
    }
    
    var localeIdentifier: String {
        switch self {
        case .system: return ""
        case .chinese: return "zh-CN"
        case .english: return "en-US"
        case .spanish: return "es-ES"
        case .french: return "fr-FR"
        case .arabic: return "ar-SA"
        case .russian: return "ru-RU"
        case .german: return "de-DE"
        case .portuguese: return "pt-BR"
        case .italian: return "it-IT"
        }
    }
}

// MARK: - Settings Model
struct AppSettings {
    var aiCircleRecognitionEnabled: Bool = true
    var circleCenterStyle: CircleCenterStyle = .crossWithCircle
    var language: AppLanguage = .system
}

// MARK: - Settings Manager
class SettingsManager: ObservableObject {
    @Published var settings = AppSettings()
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadSettings()
    }
    
    private func loadSettings() {
        settings.aiCircleRecognitionEnabled = userDefaults.bool(forKey: "ai_circle_recognition")
        
        if let styleString = userDefaults.string(forKey: "circle_center_style"),
           let style = CircleCenterStyle(rawValue: styleString) {
            settings.circleCenterStyle = style
        } else {
            settings.circleCenterStyle = .crossWithCircle
            userDefaults.set(settings.circleCenterStyle.rawValue, forKey: "circle_center_style")
        }
        
        if let languageString = userDefaults.string(forKey: "language"),
           let language = AppLanguage(rawValue: languageString) {
            settings.language = language
        } else {
            settings.language = .system
            userDefaults.set(settings.language.rawValue, forKey: "language")
        }
        
        // Set default for AI recognition if not set
        if userDefaults.object(forKey: "ai_circle_recognition") == nil {
            settings.aiCircleRecognitionEnabled = true
            userDefaults.set(true, forKey: "ai_circle_recognition")
        }
    }
    
    func updateAiCircleRecognition(_ enabled: Bool) {
        settings.aiCircleRecognitionEnabled = enabled
        userDefaults.set(enabled, forKey: "ai_circle_recognition")
    }
    
    func updateCircleCenterStyle(_ style: CircleCenterStyle) {
        settings.circleCenterStyle = style
        userDefaults.set(style.rawValue, forKey: "circle_center_style")
    }
    
    func updateLanguage(_ language: AppLanguage) {
        settings.language = language
        userDefaults.set(language.rawValue, forKey: "language")
        
        // Apply language change immediately
        if language != .system {
            UserDefaults.standard.set([language.localeIdentifier], forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
        UserDefaults.standard.synchronize()
    }
    
    func getCurrentLanguage() -> AppLanguage {
        return settings.language
    }
}

// MARK: - Circle Center Style Drawing Extension
extension CircleCenterStyle {
    func draw(in context: GraphicsContext, center: CGPoint, color: Color, scale: CGFloat = 1.0, circleRadius: CGFloat? = nil, isPreview: Bool = false) {
        let strokeWidth = isPreview ? 2.0 : 2.0 * scale
        let baseSize = isPreview ? 8.0 : 8.0 * scale
        
        switch self {
        case .dot:
            let radius = isPreview ? 3.0 : 3.0 * scale
            context.fill(
                Path(ellipseIn: CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )),
                with: .color(color)
            )
            
        case .smallCross:
            let crossSize = isPreview ? baseSize : baseSize * 3
            
            // Horizontal line
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: center.x - crossSize, y: center.y))
                    path.addLine(to: CGPoint(x: center.x + crossSize, y: center.y))
                },
                with: .color(color),
                lineWidth: strokeWidth
            )
            
            // Vertical line
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: center.x, y: center.y - crossSize))
                    path.addLine(to: CGPoint(x: center.x, y: center.y + crossSize))
                },
                with: .color(color),
                lineWidth: strokeWidth
            )
            
        case .largeCross:
            let crossRadius = circleRadius ?? (baseSize * 2)
            
            // Horizontal line
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: center.x - crossRadius, y: center.y))
                    path.addLine(to: CGPoint(x: center.x + crossRadius, y: center.y))
                },
                with: .color(color),
                lineWidth: strokeWidth
            )
            
            // Vertical line
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: center.x, y: center.y - crossRadius))
                    path.addLine(to: CGPoint(x: center.x, y: center.y + crossRadius))
                },
                with: .color(color),
                lineWidth: strokeWidth
            )
            
        case .smallCircle:
            context.stroke(
                Path(ellipseIn: CGRect(
                    x: center.x - baseSize,
                    y: center.y - baseSize,
                    width: baseSize * 2,
                    height: baseSize * 2
                )),
                with: .color(color),
                lineWidth: strokeWidth
            )
            
        case .crossWithCircle:
            let innerCircleRadius = isPreview ? baseSize * 1.2 : baseSize * 1.2
            let crossExtension = circleRadius ?? (baseSize * 2)
            
            // Draw cross extending to outer circle edge
            let crossStrokeWidth = strokeWidth
            
            // Horizontal lines (skip inner circle area)
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: center.x - crossExtension, y: center.y))
                    path.addLine(to: CGPoint(x: center.x - innerCircleRadius, y: center.y))
                },
                with: .color(color),
                lineWidth: crossStrokeWidth
            )
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: center.x + innerCircleRadius, y: center.y))
                    path.addLine(to: CGPoint(x: center.x + crossExtension, y: center.y))
                },
                with: .color(color),
                lineWidth: crossStrokeWidth
            )
            
            // Vertical lines (skip inner circle area)
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: center.x, y: center.y - crossExtension))
                    path.addLine(to: CGPoint(x: center.x, y: center.y - innerCircleRadius))
                },
                with: .color(color),
                lineWidth: crossStrokeWidth
            )
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: center.x, y: center.y + innerCircleRadius))
                    path.addLine(to: CGPoint(x: center.x, y: center.y + crossExtension))
                },
                with: .color(color),
                lineWidth: crossStrokeWidth
            )
            
            // Inner circle
            context.stroke(
                Path(ellipseIn: CGRect(
                    x: center.x - innerCircleRadius,
                    y: center.y - innerCircleRadius,
                    width: innerCircleRadius * 2,
                    height: innerCircleRadius * 2
                )),
                with: .color(color),
                lineWidth: strokeWidth * 1.2
            )
        }
    }
}