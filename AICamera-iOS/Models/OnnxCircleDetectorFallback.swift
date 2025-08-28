import Foundation
import UIKit

// Fallback implementation when ONNX Runtime is not available
class OnnxCircleDetectorFallback: ObservableObject {
    
    init() {
        print("Using fallback circle detector - ONNX Runtime not available")
    }
    
    func detect(image: UIImage) -> [Circle] {
        // Mock detection for testing UI without ONNX Runtime
        print("Fallback detector: Simulating circle detection on image size: \(image.size)")
        
        // Return mock circles for testing
        let mockCircles = [
            Circle(cx: Float(image.size.width * 0.3), 
                  cy: Float(image.size.height * 0.4), 
                  r: 50, 
                  confidence: 0.85, 
                  className: "ROI"),
            Circle(cx: Float(image.size.width * 0.7), 
                  cy: Float(image.size.height * 0.6), 
                  r: 30, 
                  confidence: 0.92, 
                  className: "RedCenter")
        ]
        
        print("Fallback detector found \(mockCircles.count) mock circles")
        return mockCircles
    }
}
