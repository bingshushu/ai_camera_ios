//
//  ContentView.swift
//  AICamera-iOS
//
//  Created by Sen on 2025/8/27.
//

import SwiftUI
import AVFoundation
import Photos
import MobileVLCKit

struct ContentView: View {
    @StateObject private var smartPlayer = SmartRTSPPlayer()  // 使用智能RTSP播放器
    @StateObject private var modelUpdateManager = ModelUpdateManager()
    @StateObject private var coordinator = VideoPlayerCoordinator()
    @StateObject private var settingsManager = SettingsManager()
    
    @State private var detector: OnnxCircleDetector?
    @State private var videoSize = CGSize.zero
    @State private var overlayImage: UIImage?
    @State private var showOverlayImage = false
    @State private var circles: [Circle] = []
    @State private var isNozzleConfirmed = false
    @State private var showSettings = false
    @State private var isDetecting = false
    
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
                
                // 智能RTSP播放器 (自动选择最优方案)
                AVVideoPlayerView(
                    player: smartPlayer.getAVPlayer(),
                    videoSize: $videoSize,
                    coordinator: coordinator
                )
                .aspectRatio(16/9, contentMode: .fit)
                .scaleEffect(rtspScale)
                .offset(rtspOffset)
                .clipped()
                
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
                                offset: imageOffset,
                                centerStyle: settingsManager.settings.circleCenterStyle
                            )
                        }
                    }
                    .aspectRatio(16/9, contentMode: .fit)
                    .clipped()
                }
                
                // Loading Indicator
                if smartPlayer.isLoading {
                    ProgressView()
                        .scaleEffect(2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                
                // Status Text with player type and detailed info
                VStack {
                    HStack {
                        VStack(alignment: .leading) {
                            HStack {
                                Text(smartPlayer.statusText)
                                    .foregroundColor(.white)
                                    .font(.headline)
                                
                                if !smartPlayer.playerType.isEmpty && smartPlayer.playerType != "None" {
                                    Text("[\(smartPlayer.playerType)]")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .background(Color.green.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                            
                            // Show additional debug info when not connected
                            if !smartPlayer.isConnected && smartPlayer.hasStreamIssue {
                                Text("🔍 尝试不同连接方式...")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                            
                            if smartPlayer.isLoading {
                                Text("⏳ 智能连接中...")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                            }
                        }
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
                            showSettings = true
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
                                Text(isDetecting ? "检测中..." : (isNozzleConfirmed ? "喷嘴确认" : "喷嘴确认"))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(
                                        isDetecting ? Color.orange :
                                        (isNozzleConfirmed ? Color.green : Color.gray)
                                    )
                                    .cornerRadius(8)
                            }
                            .disabled(isDetecting)
                            
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
                
                // Retry Button with RTSP solutions
                if smartPlayer.hasStreamIssue {
                    VStack {
                        HStack {
                            VStack(spacing: 8) {
                                Button("重试智能连接") {
                                    print("🔄 用户请求重试智能RTSP连接")
                                    smartPlayer.retry()
                                }
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                
                                Button("查看解决方案") {
                                    print("💡 显示RTSP解决方案指南")
                                    showRTSPSolutions()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                                .font(.caption)
                            }
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
        .sheet(isPresented: $showSettings) {
            SettingsView(settingsManager: settingsManager)
        }
        .alert("模型更新", isPresented: $showUpdateDialog) {
            Button("更新") {
                if let versionInfo = updateVersionInfo {
                    startModelDownload(versionInfo: versionInfo)
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("发现新的AI模型版本，是否立即更新？")
        }
        .alert("模型下载", isPresented: $modelUpdateManager.isDownloading) {
            // No buttons - this is just an info alert
        } message: {
            Text("正在下载模型，请稍候...")
        }
        .onAppear {
            setupFullscreen()
            requestPhotoLibraryPermission()
            
            // Initialize detector with model update manager
            detector = OnnxCircleDetector(modelUpdateManager: modelUpdateManager)
            
            // Validate model on startup
            if ModelValidator.checkModelFile() {
                print("ONNX model file validated successfully")
            } else {
                print("Warning: ONNX model file validation failed")
            }
            
            // Check for model updates
            checkForModelUpdate()
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
        
        // Check if AI detection is enabled
        if settingsManager.settings.aiCircleRecognitionEnabled {
            isDetecting = true
            
            DispatchQueue.global(qos: .userInitiated).async {
                // Run detection
                let detectedCircles = detector?.detect(image: capturedImage) ?? []
                
                DispatchQueue.main.async {
                    circles = detectedCircles
                    isNozzleConfirmed = true
                    isDetecting = false
                    
                    print("Detection completed, found \(detectedCircles.count) circles")
                    detectedCircles.forEach { circle in
                        print("Circle: \(circle.className) - center(\(Int(circle.cx)), \(Int(circle.cy))) radius=\(Int(circle.r)) confidence=\(String(format: "%.3f", circle.confidence))")
                    }
                }
            }
        } else {
            // Skip AI detection
            circles = []
            isNozzleConfirmed = true
            print("AI circle recognition disabled, skipping detection")
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
        isDetecting = false
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
    
    private func checkForModelUpdate() {
        Task {
            do {
                if let versionInfo = try await modelUpdateManager.checkForUpdate() {
                    await MainActor.run {
                        showUpdateDialog(versionInfo: versionInfo)
                    }
                }
            } catch {
                print("Failed to check for model update: \(error)")
            }
        }
    }
    
    @State private var showUpdateDialog = false
    @State private var updateVersionInfo: ModelVersionInfo?
    
    private func showUpdateDialog(versionInfo: ModelVersionInfo) {
        updateVersionInfo = versionInfo
        showUpdateDialog = true
    }
    
    private func startModelDownload(versionInfo: ModelVersionInfo) {
        Task {
            let success = await modelUpdateManager.downloadModel(versionInfo) { progress in
                DispatchQueue.main.async {
                    // Update progress if needed
                    print("Download progress: \(progress * 100)%")
                }
            }
            
            await MainActor.run {
                if success {
                    print("Model update successful")
                    // Reload the detector with the new model
                    do {
                        try detector?.reloadModel()
                        print("Model reloaded successfully")
                    } catch {
                        print("Failed to reload model: \(error)")
                    }
                } else {
                    print("Model update failed")
                }
            }
        }
    }
    
    private func showRTSPSolutions() {
        print("""
        🔧 RTSP播放解决方案:
        
        当前状态: \(smartPlayer.statusText)
        播放器类型: \(smartPlayer.playerType)
        
        解决方案:
        1. 检查相机是否支持HTTP MJPEG流
        2. 尝试URL: http://admin:admin@192.168.1.87/mjpeg.cgi
        3. 登录相机管理页面检查流配置
        4. 考虑部署HLS转换服务
        
        详细文档: 请查看 RTSP_ULTIMATE_SOLUTION.md
        """)
    }
}

#Preview {
    ContentView()
}
