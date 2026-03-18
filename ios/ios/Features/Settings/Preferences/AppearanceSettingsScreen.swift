import SwiftUI

struct AppearanceSettingsView: View {
    @State private var selectedTheme: String = "Auto"

    var body: some View {
        AppScaffold(
            title: "外観",
            subtitle: "VISUAL INTERFACE"
        ) {
            VStack(alignment: .leading, spacing: 32) {
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("INTERFACE THEME")
                            .prototypeFont(size: 11, weight: .black, role: .data)
                            .kerning(2.0)
                            .foregroundStyle(PrototypeTheme.textSecondary)
                        Spacer()
                        Text("UI-MODE")
                            .prototypeFont(size: 9, weight: .black, role: .data)
                            .foregroundStyle(PrototypeTheme.textTertiary.opacity(0.6))
                    }
                    .padding(.horizontal, 4)

                    HStack(spacing: 16) {
                        themeCard(title: "LIGHT", icon: "sun.max.fill", id: "Light")
                        themeCard(title: "DARK", icon: "moon.fill", id: "Dark")
                    }
                    
                    themeCard(title: "SYSTEM DEFAULT (AUTO)", icon: "desktopcomputer", id: "Auto", fullWidth: true)
                }

                // --- DESIGN NOTE ---
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "paintbrush.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(PrototypeTheme.accent)
                        Text("DESIGN GUIDELINE")
                            .prototypeFont(size: 9, weight: .black, role: .data)
                            .foregroundStyle(PrototypeTheme.textSecondary)
                    }
                    
                    Text("Urban Serendipity は、時間帯や周囲の環境に合わせた動的な背景演出を採用しています。システム設定に従うことで、より没入感のある体験が可能です。")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PrototypeTheme.textTertiary)
                        .lineSpacing(4)
                }
                .padding(20)
                .background(PrototypeTheme.surfaceMuted.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private func themeCard(title: String, icon: String, id: String, fullWidth: Bool = false) -> some View {
        Button {
            selectedTheme = id
        } label: {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(selectedTheme == id ? .white : PrototypeTheme.accent)
                
                Text(title)
                    .prototypeFont(size: 10, weight: .black, role: .data)
                    .kerning(1.5)
                    .foregroundStyle(selectedTheme == id ? .white : PrototypeTheme.textSecondary)
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(selectedTheme == id ? PrototypeTheme.accent : PrototypeTheme.surface)
                    .shadow(color: Color.black.opacity(selectedTheme == id ? 0.2 : 0.05), radius: 10, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(PrototypeTheme.border, lineWidth: selectedTheme == id ? 0 : 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
