import SwiftUI

// Alternative app configuration - not using @main since it's defined in the root AICamera_iOSApp.swift
struct AlternativeAICamera_iOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .onAppear {
                    // Configure app for landscape orientation
                    configureOrientation()
                }
        }
    }
    
    private func configureOrientation() {
        // Lock to landscape orientation
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
        }
        
        // Keep screen on during video playback
        UIApplication.shared.isIdleTimerDisabled = true
    }
}
