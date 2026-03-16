import SwiftUI
import UIKit

struct EncounterDetailView: View {
    let encounter: Encounter
    @State private var showsProfile = false
    @State private var showsLyricModal = false

    var body: some View {
        AppScaffold(
            title: encounter.track.title,
            subtitle: "3分前・渋谷駅",
            accentColor: encounter.track.color
        ) {
            VStack(alignment: .leading, spacing: 24) {
                // Main Track Info Card
                VStack(spacing: 24) {
                    MockArtworkView(color: encounter.track.color, symbol: "music.note", size: 160)
                        .shadow(color: encounter.track.color.opacity(0.3), radius: 30, x: 0, y: 15)
                    
                    VStack(spacing: 8) {
                        Text(encounter.track.title)
                            .font(PrototypeTheme.Typography.Encounter.screenTitle)
                            .foregroundStyle(PrototypeTheme.textPrimary)
                            .tracking(-0.5)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .truncationMode(.tail)
                        
                        Text(encounter.track.artist)
                            .font(PrototypeTheme.Typography.Encounter.sectionTitle)
                            .foregroundStyle(PrototypeTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Button(action: { showsProfile = true }) {
                        HStack(spacing: 8) {
                            MockArtworkView(color: .gray, symbol: "person.fill", size: 24)
                            Text(encounter.userName)
                                .font(PrototypeTheme.Typography.Encounter.action)
                            Image(systemName: "chevron.right")
                                .font(PrototypeTheme.Typography.Encounter.metaCompact)
                        }
                        .foregroundStyle(PrototypeTheme.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(PrototypeTheme.surface.opacity(0.6))
                        .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)

                // Lyric Fragment - Glassmorphic
                GlassmorphicCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "quote.opening")
                                .font(PrototypeTheme.Typography.Encounter.action)
                                .foregroundStyle(encounter.track.color)
                            Spacer()
                            Text("歌詞の断片")
                                .font(PrototypeTheme.Typography.Encounter.eyebrow)
                                .foregroundStyle(PrototypeTheme.textSecondary)
                                .kerning(1.2)
                        }
                        
                        Text(encounter.lyric)
                            .prototypeFont(size: 22, weight: .bold, role: .accent)
                            .italic()
                            .foregroundStyle(PrototypeTheme.textPrimary)
                            .lineSpacing(4)
                        
                        HStack {
                            Spacer()
                            Image(systemName: "quote.closing")
                                .font(PrototypeTheme.Typography.Encounter.action)
                                .foregroundStyle(encounter.track.color)
                        }
                    }
                }

                // Interaction Area
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "heart.fill")
                                Text("いいね")
                            }
                            .font(PrototypeTheme.Typography.Encounter.action)
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(encounter.track.color)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        
                        Button(action: {}) {
                            Image(systemName: "ellipsis")
                                .font(PrototypeTheme.Typography.Encounter.sectionTitle)
                                .foregroundStyle(PrototypeTheme.textPrimary)
                                .frame(width: 52, height: 52)
                                .background(PrototypeTheme.surfaceMuted)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                    
                    PrimaryButton(title: "歌詞を残す", systemImage: "sparkles") {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showsLyricModal = true
                    }
                }

                // Extra Debug Section
                NavigationLink {
                    RealtimeDemoView()
                } label: {
                    HStack {
                        Text("リアルタイム演出を見る")
                            .font(PrototypeTheme.Typography.Encounter.metaCompact)
                            .kerning(1.0)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(PrototypeTheme.Typography.Encounter.metaCompact)
                    }
                    .foregroundStyle(PrototypeTheme.textSecondary)
                    .padding(16)
                    .background(PrototypeTheme.surfaceMuted.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showsProfile) {
            OtherUserProfileView()
        }
        .sheet(isPresented: $showsLyricModal) {
            LyricInputModalView()
        }
    }
}

