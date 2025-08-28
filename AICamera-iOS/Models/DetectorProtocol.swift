import Foundation
import UIKit

// Protocol to allow switching between ONNX and fallback detectors
protocol CircleDetectorProtocol: ObservableObject {
    func detect(image: UIImage) -> [Circle]
}

// Extension to make both detectors conform to the protocol
extension OnnxCircleDetectorFallback: CircleDetectorProtocol {}

#if canImport(onnxruntime_objc)
extension OnnxCircleDetector: CircleDetectorProtocol {}
#endif
