# AI Camera iOS

An iOS implementation of the AI Camera application with RTSP streaming and ONNX-based circle detection.

## Features

- **RTSP Video Streaming**: Native AVPlayer support for RTSP streams with authentication
- **AI Circle Detection**: ONNX Runtime integration for YOLOv8 model inference
- **Real-time Overlay**: Dynamic circle detection overlay with zoom/pan gestures
- **Screenshot Capture**: Save video frames to photo library
- **Fullscreen Landscape**: Optimized for landscape viewing
- **Transform Controls**: Nozzle confirmation and red light alignment features

## Requirements

- iOS 15.0+
- Xcode 14.0+
- CocoaPods

## Setup

1. Install dependencies:
   ```bash
   pod install
   ```

2. Add your ONNX model file:
   - Place `model.onnx` in the app bundle (AICamera-iOS folder)
   - The model should be trained for circle detection with classes: "ROI" and "RedCenter"

3. Configure RTSP settings:
   - Update RTSP URL, username, and password in `RTSPPlayer.swift`
   - Default: `rtsp://192.168.1.88/11` with admin/admin credentials

## Architecture

### Core Components

- **RTSPPlayer**: Manages RTSP video streaming using AVPlayer
- **OnnxCircleDetector**: Handles ONNX model inference for circle detection
- **VideoPlayerView**: UIKit bridge for video rendering and frame capture
- **OverlayView**: SwiftUI canvas for drawing detection results
- **ContentView**: Main UI with gesture handling and controls

### Key Features

- **Letterbox Preprocessing**: Maintains aspect ratio during model inference
- **NMS (Non-Maximum Suppression)**: Filters overlapping detections
- **Transform Synchronization**: Applies image transforms to video stream
- **Permission Management**: Handles photo library access permissions

## Usage

1. **Connect**: App automatically connects to configured RTSP stream
2. **Nozzle Confirmation**: Tap to capture frame and run circle detection
3. **Zoom/Pan**: Use gestures to adjust overlay image positioning
4. **Red Light Alignment**: Apply image transforms to video stream
5. **Screenshot**: Save current video frame to photo library
6. **Reset**: Clear all overlays and return to initial state

## Model Requirements

The ONNX model should:
- Accept input shape: [1, 3, H, W] where H=W (square input)
- Output YOLOv8 format: [1, 6, N] where 6 = 4(bbox) + 2(classes)
- Support classes: "ROI" (index 0) and "RedCenter" (index 1)
- Be optimized for mobile inference

## Configuration

### RTSP Settings
```swift
private let defaultRTSPURL = "rtsp://192.168.1.88/11"
private let defaultUsername = "admin"
private let defaultPassword = "admin"
```

### Detection Parameters
```swift
private let confThreshold: Float = 0.1  // Confidence threshold
private let nmsThreshold: Float = 0.48  // NMS threshold
```

## Permissions

The app requires:
- Photo Library Access: For saving screenshots
- Network Access: For RTSP streaming (NSAppTransportSecurity configured)

## Notes

- Designed for landscape orientation only
- Optimized for 16:9 aspect ratio video streams
- Uses native iOS frameworks for best performance
- AVPlayer provides hardware-accelerated video decoding
