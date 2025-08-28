import Foundation
import UIKit

class ModelValidator {
    static func validateModel() -> Bool {
        do {
            let detector = OnnxCircleDetector()
            
            // Create a test image using UIGraphics
            UIGraphicsBeginImageContextWithOptions(CGSize(width: 320, height: 320), false, 0.0)
            UIColor.black.setFill()
            UIRectFill(CGRect(origin: .zero, size: CGSize(width: 320, height: 320)))
            let testImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            if let image = testImage {
                print("Testing ONNX model with test image...")
                let circles = detector.detect(image: image)
                print("Model validation successful - detected \(circles.count) circles")
                return true
            } else {
                print("Failed to create test image")
                return false
            }
        } catch {
            print("Model validation failed: \(error)")
            return false
        }
    }
    
    static func checkModelFile() -> Bool {
        guard let modelPath = Bundle.main.path(forResource: "model", ofType: "onnx") else {
            print("Model file not found in bundle")
            return false
        }
        
        let fileManager = FileManager.default
        let fileExists = fileManager.fileExists(atPath: modelPath)
        
        if fileExists {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: modelPath)
                let fileSize = attributes[.size] as? Int64 ?? 0
                print("Model file found: \(modelPath)")
                print("Model file size: \(fileSize) bytes")
                return true
            } catch {
                print("Error reading model file attributes: \(error)")
                return false
            }
        } else {
            print("Model file does not exist at path: \(modelPath)")
            return false
        }
    }
}
