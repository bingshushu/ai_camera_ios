import SwiftUI

struct ControlsView: View {
    @Binding var isNozzleConfirmed: Bool
    @Binding var showOverlayImage: Bool
    @Binding var hasStreamIssue: Bool
    
    let onNozzleConfirm: () -> Void
    let onRedLightAlign: () -> Void
    let onScreenshot: () -> Void
    let onRetry: () -> Void
    let onSettings: () -> Void
    
    var body: some View {
        VStack {
            // Top controls
            HStack {
                // Retry button (when stream has issues)
                if hasStreamIssue {
                    Button("重试") {
                        onRetry()
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Spacer()
                
                // Settings button
                Button("设置") {
                    onSettings()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.top)
            
            Spacer()
            
            // Side controls
            HStack {
                Spacer()
                
                VStack(spacing: 16) {
                    // Nozzle confirmation button
                    Button(action: onNozzleConfirm) {
                        Text("喷嘴确认")
                            .foregroundColor(.black)
                            .padding()
                            .background(isNozzleConfirmed ? Color.orange : Color.yellow)
                            .cornerRadius(8)
                    }
                    
                    // Red light alignment button
                    if showOverlayImage {
                        Button("红光对中") {
                            onRedLightAlign()
                        }
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding(.trailing)
            }
            
            // Bottom controls
            HStack {
                Spacer()
                
                Button("截图") {
                    onScreenshot()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.trailing)
                .padding(.bottom)
            }
        }
    }
}

struct StatusOverlay: View {
    let statusText: String
    let isLoading: Bool
    
    var body: some View {
        VStack {
            HStack {
                Text(statusText)
                    .foregroundColor(.white)
                    .padding()
                Spacer()
            }
            Spacer()
        }
        
        if isLoading {
            ProgressView()
                .scaleEffect(2)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
        }
    }
}
