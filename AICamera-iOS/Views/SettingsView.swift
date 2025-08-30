import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showStyleDialog = false
    @State private var showLanguageDialog = false
    
    var body: some View {
        NavigationView {
            List {
                // AI Circle Recognition Section
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AI圆心识别")
                                .font(.headline)
                            Text("启用或禁用AI圆心识别功能")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { settingsManager.settings.aiCircleRecognitionEnabled },
                            set: { settingsManager.updateAiCircleRecognition($0) }
                        ))
                    }
                    .padding(.vertical, 8)
                }
                
                // Circle Center Style Section
                Section {
                    Button(action: { showStyleDialog = true }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("圆心样式")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("选择圆心显示样式")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            HStack(spacing: 8) {
                                CircleCenterStylePreview(
                                    style: settingsManager.settings.circleCenterStyle
                                )
                                Text(settingsManager.settings.circleCenterStyle.displayName)
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Language Section
                Section {
                    Button(action: { showLanguageDialog = true }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("语言")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("选择应用语言")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            HStack(spacing: 8) {
                                Text(settingsManager.settings.language.displayName)
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showStyleDialog) {
            CircleCenterStyleDialog(
                settingsManager: settingsManager,
                isPresented: $showStyleDialog
            )
        }
        .sheet(isPresented: $showLanguageDialog) {
            LanguageDialog(
                settingsManager: settingsManager,
                isPresented: $showLanguageDialog
            )
        }
    }
}

struct CircleCenterStylePreview: View {
    let style: CircleCenterStyle
    let color: Color
    
    init(style: CircleCenterStyle, color: Color = .primary) {
        self.style = style
        self.color = color
    }
    
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            style.draw(in: context, center: center, color: color, isPreview: true)
        }
        .frame(width: 40, height: 40)
    }
}

struct CircleCenterStyleDialog: View {
    let settingsManager: SettingsManager
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                ForEach(CircleCenterStyle.allCases, id: \.self) { style in
                    Button(action: {
                        settingsManager.updateCircleCenterStyle(style)
                        isPresented = false
                    }) {
                        HStack {
                            CircleCenterStylePreview(style: style)
                            Text(style.displayName)
                                .foregroundColor(.primary)
                            Spacer()
                            if settingsManager.settings.circleCenterStyle == style {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("圆心样式")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct LanguageDialog: View {
    let settingsManager: SettingsManager
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    Button(action: {
                        settingsManager.updateLanguage(language)
                        isPresented = false
                        
                        // Show restart prompt if needed
                        if language != .system {
                            // In a real app, you might want to show an alert here
                            // asking the user to restart the app for language changes to take effect
                        }
                    }) {
                        HStack {
                            Text(language.displayName)
                                .foregroundColor(.primary)
                            Spacer()
                            if settingsManager.settings.language == language {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("语言")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView(settingsManager: SettingsManager())
}