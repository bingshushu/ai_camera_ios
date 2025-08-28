//
//  ContentView.swift
//  AICamera-iOS
//
//  Created by Sen on 2025/8/27.
//

import SwiftUI
import AVFoundation
import Photos

struct ContentView: View {
    @StateObject private var rtspPlayer = RTSPPlayer()
    @StateObject private var detector = OnnxCircleDetector()  // Using real ONNX detector now
    @StateObject private var coordinator = VideoPlayerCoordinator()
    
    @State private var videoSize = CGSize.zero
    @State private var overlayImage: UIImage?
    @State private var showOverlayImage = false
    @State private var circles: [Circle] = []
    @State private var isNozzleConfirmed = false
    
    // Transform states
    @State private var imageScale: CGFloat = 1.0
    @State private var baseScale: CGFloat = 1.0
    @State private var imageOffset = CGSize.zero
    @State private var rtspScale: CGFloat = 1.0
    @State private var rtspOffset = CGSize.zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                // RTSP Video Player
                if let player = rtspPlayer.player {
                    VideoPlayerView(player: player, videoSize: $videoSize, coordinator: coordinator)
                        .aspectRatio(16/9, contentMode: .fit)
                        .scaleEffect(rtspScale)
                        .offset(rtspOffset)
                        .clipped()
                }
                
                // Overlay Image and Circles
                if let overlayImage = overlayImage {
                    ZStack {
                        // Overlay Image (only when showOverlayImage is true)
                        if showOverlayImage {
                            Image(uiImage: overlayImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaleEffect(imageScale)
                                .offset(imageOffset)
                                .gesture(
                                    MagnificationGesture()
                                        .simultaneously(with: DragGesture())
                                        .onChanged { value in
                                            if let magnification = value.first {
                                                let newScale = baseScale * magnification
                                                imageScale = max(baseScale, min(newScale, baseScale * 3))
                                            }
                                            if let drag = value.second {
                                                imageOffset = drag.translation
                                            }
                                        }
                                )
                        }
                        
                        // Circle Overlay (always visible when circles exist)
                        if !circles.isEmpty {
                            CircleOverlayView(
                                circles: circles,
                                imageSize: overlayImage.size,
                                scale: imageScale,
                                offset: imageOffset
                            )
                        }
                    }
                    .aspectRatio(16/9, contentMode: .fit)
                    .clipped()
                }
                
                // Loading Indicator
                if rtspPlayer.isLoading {
                    ProgressView()
                        .scaleEffect(2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                
                // Status Text
                VStack {
                    HStack {
                        Text(rtspPlayer.statusText)
                            .foregroundColor(.white)
                            .padding()
                        Spacer()
                    }
                    Spacer()
                }
                
                // Control Buttons
                VStack {
                    HStack {
                        Spacer()
                        
                        // Settings Button
                        Button("设置") {
                            // TODO: Implement settings
                            print("Settings tapped")
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.trailing)
                    }
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 16) {
                            // Nozzle Confirmation Button
                            Button(action: {
                                if !isNozzleConfirmed {
                                    captureAndDetect()
                                } else {
                                    resetAll()
                                }
                            }) {
                                Text("喷嘴确认")
                                    .foregroundColor(.black)
                                    .padding()
                                    .background(isNozzleConfirmed ? Color.orange : Color.yellow)
                                    .cornerRadius(8)
                            }
                            
                            // Red Light Alignment Button
                            if showOverlayImage && overlayImage != nil {
                                Button("红光对中") {
                                    applyTransformToRTSP()
                                }
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                        .padding(.trailing)
                    }
                    
                    HStack {
                        Spacer()
                        
                        // Screenshot Button
                        Button("截图") {
                            takeScreenshot()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.trailing)
                        .padding(.bottom)
                    }
                }
                
                // Retry Button (when stream has issues)
                if rtspPlayer.hasStreamIssue {
                    VStack {
                        HStack {
                            Button("重试") {
                                rtspPlayer.retry()
                            }
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding(.leading)
                            
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden()
        .onAppear {
            setupFullscreen()
            requestPhotoLibraryPermission()
            
            // Validate model on startup
            if ModelValidator.checkModelFile() {
                print("ONNX model file validated successfully")
            } else {
                print("Warning: ONNX model file validation failed")
            }
        }
    }
    
    private func setupFullscreen() {
        // Force landscape orientation
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
        }
    }
    
    private func requestPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized, .limited:
                print("Photo library access granted")
            case .denied, .restricted:
                print("Photo library access denied")
            case .notDetermined:
                print("Photo library access not determined")
            @unknown default:
                break
            }
        }
    }
    
    private func captureAndDetect() {
        guard let capturedImage = coordinator.screenshotCapture.captureFrame() else {
            print("Failed to capture frame")
            return
        }
        
        overlayImage = capturedImage
        showOverlayImage = true
        
        // Calculate base scale for aspect fit
        let imageSize = capturedImage.size
        let containerAspectRatio: CGFloat = 16/9
        let imageAspectRatio = imageSize.width / imageSize.height
        
        if imageAspectRatio > containerAspectRatio {
            // Image is wider, fit to width
            baseScale = 1.0
        } else {
            // Image is taller, fit to height
            baseScale = containerAspectRatio / imageAspectRatio
        }
        
        imageScale = baseScale
        imageOffset = .zero
        
        // Run detection
        let detectedCircles = detector.detect(image: capturedImage)
        circles = detectedCircles
        isNozzleConfirmed = true
        
        print("Detection completed, found \(detectedCircles.count) circles")
        detectedCircles.forEach { circle in
            print("Circle: \(circle.className) - center(\(Int(circle.cx)), \(Int(circle.cy))) radius=\(Int(circle.r)) confidence=\(String(format: "%.3f", circle.confidence))")
        }
    }
    
    private func resetAll() {
        imageScale = 1.0
        imageOffset = .zero
        rtspScale = 1.0
        rtspOffset = .zero
        showOverlayImage = false
        overlayImage = nil
        circles = []
        isNozzleConfirmed = false
    }
    
    private func applyTransformToRTSP() {
        rtspScale = imageScale
        rtspOffset = imageOffset
        showOverlayImage = false
        
        print("Applied transform to RTSP - scale: \(String(format: "%.3f", rtspScale)), offset: (\(Int(rtspOffset.width)), \(Int(rtspOffset.height)))")
    }
    
    private func takeScreenshot() {
        guard let image = coordinator.screenshotCapture.captureFrame() else {
            print("Failed to capture screenshot")
            return
        }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    print("Screenshot saved to photo library")
                } else {
                    print("Failed to save screenshot: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
