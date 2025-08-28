import Foundation
import UIKit
import onnxruntime_objc

struct Circle {
    let cx: Float
    let cy: Float
    let r: Float
    let confidence: Float
    let className: String
}

private struct Detection {
    let x1: Float
    let y1: Float
    let x2: Float
    let y2: Float
    let confidence: Float
    let classId: Int
}

private struct LetterboxResult {
    let image: UIImage
    let padX: Float
    let padY: Float
    let scale: Float
}

class OnnxCircleDetector: ObservableObject {
    private var session: ORTSession?
    private let environment: ORTEnv
    
    // Model configuration
    private var modelInputSize = 320
    private let confThreshold: Float = 0.1
    private let nmsThreshold: Float = 0.48
    private let classNames = ["ROI", "RedCenter"]
    
    init() {
        environment = (try? ORTEnv(loggingLevel: .warning)) ?? (try! ORTEnv(loggingLevel: .warning))
        do {
            try loadModel()
        } catch {
            print("Failed to initialize ONNX detector: \(error)")
        }
    }
    
    deinit {
        session = nil
    }
    
    private func loadModel() throws {
        guard let modelPath = Bundle.main.path(forResource: "model", ofType: "onnx") else {
            throw NSError(domain: "OnnxCircleDetector", code: 1, userInfo: [NSLocalizedDescriptionKey: "Model file not found: model.onnx"])
        }
        
        let options = try ORTSessionOptions()
        session = try ORTSession(env: environment, modelPath: modelPath, sessionOptions: options)
        
        // Get model input size
        getModelInputSize()
        logModelInfo()
    }
    
    private func getModelInputSize() {
        // Use default model input size
        modelInputSize = 320
        print("Using default model input size: \(modelInputSize)x\(modelInputSize)")
    }
    
    private func logModelInfo() {
        guard let session = session else { return }
        
        do {
            let inputNames = try session.inputNames()
            let outputNames = try session.outputNames()
            
            print("=== Model Info ===")
            print("Inputs: \(inputNames)")
            print("Outputs: \(outputNames)")
        } catch {
            print("Failed to log model info: \(error)")
        }
    }
    
    func detect(image: UIImage) -> [Circle] {
        guard let session = session else {
            print("Session not initialized")
            return []
        }
        
        do {
            print("Starting detection, input image size: \(image.size)")
            
            // 1. Preprocess image with letterbox
            let letterbox = createLetterboxImage(from: image, targetSize: CGSize(width: modelInputSize, height: modelInputSize))
            let inputArray = imageToFloatArray(letterbox.image, normalize: true)
            
            // 2. Create input tensor
            let inputNames = try session.inputNames()
            guard let inputName = inputNames.first else {
                throw NSError(domain: "OnnxCircleDetector", code: 2, userInfo: [NSLocalizedDescriptionKey: "No input name found"])
            }
            
            let inputShape: [NSNumber] = [1, 3, NSNumber(value: modelInputSize), NSNumber(value: modelInputSize)]
            let inputTensor = try ORTValue(tensorData: NSMutableData(bytes: inputArray, length: inputArray.count * MemoryLayout<Float>.size),
                                         elementType: .float,
                                         shape: inputShape)
            
            // 3. Run inference
            let outputs = try session.run(withInputs: [inputName: inputTensor], outputNames: Set<String>(), runOptions: nil)
            
            // 4. Parse output
            let circles = try parseYoloOutput(outputs: outputs, letterbox: letterbox, originalSize: image.size)
            
            print("Detection completed, found \(circles.count) targets")
            return circles
            
        } catch {
            print("Detection failed: \(error)")
            return []
        }
    }
    
    private func createLetterboxImage(from image: UIImage, targetSize: CGSize) -> LetterboxResult {
        let srcSize = image.size
        
        guard srcSize.width > 0 && srcSize.height > 0 else {
            let blankImage = UIImage(color: .black, size: targetSize) ?? image
            return LetterboxResult(image: blankImage, padX: 0, padY: 0, scale: 1.0)
        }
        
        // Calculate scale to maintain aspect ratio
        let scale = min(targetSize.width / srcSize.width, targetSize.height / srcSize.height)
        let newSize = CGSize(width: srcSize.width * scale, height: srcSize.height * scale)
        
        // Calculate padding
        let padX = (targetSize.width - newSize.width) / 2
        let padY = (targetSize.height - newSize.height) / 2
        
        // Create letterbox image
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        // Fill with black background
        UIColor.black.setFill()
        UIRectFill(CGRect(origin: .zero, size: targetSize))
        
        // Draw resized image centered
        let drawRect = CGRect(x: padX, y: padY, width: newSize.width, height: newSize.height)
        image.draw(in: drawRect)
        
        let letterboxImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        
        return LetterboxResult(image: letterboxImage, padX: Float(padX), padY: Float(padY), scale: Float(scale))
    }
    
    private func imageToFloatArray(_ image: UIImage, normalize: Bool = true) -> [Float] {
        guard let cgImage = image.cgImage else { return [] }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var pixelData = [UInt8](repeating: 0, count: height * width * bytesPerPixel)
        
        let context = CGContext(data: &pixelData,
                               width: width,
                               height: height,
                               bitsPerComponent: bitsPerComponent,
                               bytesPerRow: bytesPerRow,
                               space: CGColorSpaceCreateDeviceRGB(),
                               bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Convert to CHW format
        var output = [Float](repeating: 0, count: 3 * height * width)
        let rOffset = 0
        let gOffset = height * width
        let bOffset = 2 * height * width
        
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = (y * width + x) * bytesPerPixel
                let r = pixelData[pixelIndex]
                let g = pixelData[pixelIndex + 1]
                let b = pixelData[pixelIndex + 2]
                
                let chwIndex = y * width + x
                if normalize {
                    output[rOffset + chwIndex] = Float(r) / 255.0
                    output[gOffset + chwIndex] = Float(g) / 255.0
                    output[bOffset + chwIndex] = Float(b) / 255.0
                } else {
                    output[rOffset + chwIndex] = Float(r)
                    output[gOffset + chwIndex] = Float(g)
                    output[bOffset + chwIndex] = Float(b)
                }
            }
        }
        
        return output
    }
    
    private func parseYoloOutput(outputs: [String: ORTValue], letterbox: LetterboxResult, originalSize: CGSize) throws -> [Circle] {
        guard let outputValue = outputs.values.first else {
            throw NSError(domain: "OnnxCircleDetector", code: 3, userInfo: [NSLocalizedDescriptionKey: "No output found"])
        }
        
        let tensorData = try outputValue.tensorData() as Data
        let floatArray = tensorData.withUnsafeBytes { bytes in
            Array(bytes.bindMemory(to: Float.self))
        }
        
        let tensorTypeInfo = try outputValue.tensorTypeAndShapeInfo()
        let shape = tensorTypeInfo.shape.map { Int(truncating: $0) }
        
        print("Output shape: \(shape)")
        
        guard shape.count == 3 else {
            throw NSError(domain: "OnnxCircleDetector", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unsupported output shape"])
        }
        
        let _ = shape[0]
        let numFeatures = shape[1]
        let numAnchors = shape[2]
        
        let expectedFeatures = 4 + classNames.count
        if numFeatures != expectedFeatures {
            print("Feature count mismatch, expected: \(expectedFeatures), actual: \(numFeatures)")
        }
        
        // Parse detections
        var detections: [Detection] = []
        let isTransposed = numFeatures > numAnchors
        let actualAnchors = isTransposed ? numFeatures : numAnchors
        let actualFeatures = isTransposed ? numAnchors : numFeatures
        
        print("Data format: \(isTransposed ? "transposed" : "standard") - anchors: \(actualAnchors), features: \(actualFeatures)")
        
        for i in 0..<actualAnchors {
            let xCenter: Float
            let yCenter: Float
            let width: Float
            let height: Float
            
            if isTransposed {
                xCenter = floatArray[i * actualFeatures + 0]
                yCenter = floatArray[i * actualFeatures + 1]
                width = floatArray[i * actualFeatures + 2]
                height = floatArray[i * actualFeatures + 3]
            } else {
                xCenter = floatArray[i]
                yCenter = floatArray[actualAnchors + i]
                width = floatArray[2 * actualAnchors + i]
                height = floatArray[3 * actualAnchors + i]
            }
            
            // Calculate class scores
            var maxScore: Float = -1
            var maxClassId = -1
            for c in 0..<classNames.count {
                let score: Float = isTransposed ?
                    floatArray[i * actualFeatures + (4 + c)] :
                    floatArray[(4 + c) * actualAnchors + i]
                
                if score > maxScore {
                    maxScore = score
                    maxClassId = c
                }
            }
            
            // Apply confidence threshold
            if maxScore >= confThreshold {
                let x1 = xCenter - width / 2
                let y1 = yCenter - height / 2
                let x2 = xCenter + width / 2
                let y2 = yCenter + height / 2
                
                detections.append(Detection(x1: x1, y1: y1, x2: x2, y2: y2, confidence: maxScore, classId: maxClassId))
            }
        }
        
        print("After confidence threshold: \(detections.count) candidates")
        
        // Apply NMS
        let nmsDetections = applyNMS(detections: detections, threshold: nmsThreshold)
        print("After NMS: \(nmsDetections.count) detections")
        
        // Convert to circles and map back to original coordinates
        return nmsDetections.map { detection in
            convertDetectionToCircle(detection: detection, letterbox: letterbox, originalSize: originalSize)
        }
    }
    
    private func applyNMS(detections: [Detection], threshold: Float) -> [Detection] {
        guard !detections.isEmpty else { return [] }
        
        let sortedDetections = detections.sorted { $0.confidence > $1.confidence }
        var result: [Detection] = []
        var remaining = sortedDetections
        
        while !remaining.isEmpty {
            let current = remaining.removeFirst()
            result.append(current)
            
            remaining.removeAll { other in
                calculateIoU(det1: current, det2: other) > threshold
            }
        }
        
        return result
    }
    
    private func calculateIoU(det1: Detection, det2: Detection) -> Float {
        let x1 = max(det1.x1, det2.x1)
        let y1 = max(det1.y1, det2.y1)
        let x2 = min(det1.x2, det2.x2)
        let y2 = min(det1.y2, det2.y2)
        
        guard x2 > x1 && y2 > y1 else { return 0 }
        
        let intersection = (x2 - x1) * (y2 - y1)
        let area1 = (det1.x2 - det1.x1) * (det1.y2 - det1.y1)
        let area2 = (det2.x2 - det2.x1) * (det2.y2 - det2.y1)
        let union = area1 + area2 - intersection
        
        return union > 0 ? intersection / union : 0
    }
    
    private func convertDetectionToCircle(detection: Detection, letterbox: LetterboxResult, originalSize: CGSize) -> Circle {
        // Calculate center point in model output coordinates
        let centerX = (detection.x1 + detection.x2) / 2
        let centerY = (detection.y1 + detection.y2) / 2
        
        // Calculate radius
        let width = detection.x2 - detection.x1
        let height = detection.y2 - detection.y1
        let radius = max(width, height) / 2
        
        // Remove letterbox padding
        let centerXNoPad = centerX - letterbox.padX
        let centerYNoPad = centerY - letterbox.padY
        
        // Scale back to original size
        let originalCenterX = centerXNoPad / letterbox.scale
        let originalCenterY = centerYNoPad / letterbox.scale
        let originalRadius = radius / letterbox.scale
        
        let className = detection.classId < classNames.count ? classNames[detection.classId] : "Unknown"
        
        print("Detected \(className): center(\(Int(originalCenterX)), \(Int(originalCenterY))) radius=\(Int(originalRadius)) confidence=\(String(format: "%.3f", detection.confidence))")
        
        return Circle(
            cx: originalCenterX,
            cy: originalCenterY,
            r: originalRadius,
            confidence: detection.confidence,
            className: className
        )
    }
}

