import SwiftUI
import UIKit

struct EncounterDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let encounter: Encounter
    @State private var showsProfile = false
    @State private var showsLyricModal = false

    var body: some View {
        ZStack {
            PrototypeTheme.background.ignoresSafeArea()

            LinearGradient(
                colors: [
                    encounter.track.color.opacity(0.12),
                    PrototypeTheme.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Navigation Header
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(PrototypeTheme.textPrimary)
                                .frame(width: 44, height: 44, alignment: .leading)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("ENCOUNTERED")
                                .font(PrototypeTheme.Typography.font(size: 10, weight: .black))
                                .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.6))
                                .tracking(1.5)

                            Text(encounter.relativeTime.uppercased())
                                .font(PrototypeTheme.Typography.font(size: 12, weight: .bold, role: .data))
                                .foregroundStyle(encounter.track.color)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    // Hero Section: Music + Person
                    VStack(spacing: 40) {
                        ZStack(alignment: .bottomTrailing) {
                            MockArtworkView(color: encounter.track.color, symbol: "music.note", size: 280, artwork: encounter.track.artwork)
                                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                                .shadow(color: encounter.track.color.opacity(0.25), radius: 50, x: 0, y: 25)

                            EncounterAvatarView(userName: encounter.userName, color: encounter.track.color, size: 84)
                                .overlay(
                                    Circle()
                                        .stroke(PrototypeTheme.background, lineWidth: 6)
                                )
                                .offset(x: 24, y: 24)
                        }
                        .padding(.top, 40)
                        .padding(.trailing, 24)

                        VStack(spacing: 16) {
                            VStack(spacing: 4) {
                                Text(encounter.userName)
                                    .font(PrototypeTheme.Typography.font(size: 18, weight: .bold))
                                    .foregroundStyle(PrototypeTheme.textSecondary)
                                
                                Text("が聴いていた曲")
                                    .font(PrototypeTheme.Typography.Encounter.eyebrow)
                                    .foregroundStyle(PrototypeTheme.textTertiary)
                            }

                            VStack(spacing: 8) {
                                Text(encounter.track.title)
                                    .font(PrototypeTheme.Typography.font(size: 38, weight: .black))
                                    .foregroundStyle(PrototypeTheme.textPrimary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .tracking(-1)

                                Text(encounter.track.artist)
                                    .font(PrototypeTheme.Typography.font(size: 20, weight: .medium))
                                    .foregroundStyle(encounter.track.color)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, 32)
                    }

                    // Shared Memory / Lyric
                    if !encounter.lyric.isEmpty {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack(spacing: 12) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(encounter.track.color)
                                
                                Text("記憶の欠片")
                                    .font(PrototypeTheme.Typography.Encounter.eyebrow)
                                    .foregroundStyle(PrototypeTheme.textSecondary)
                            }
                            
                            Text(encounter.lyric)
                                .font(PrototypeTheme.Typography.font(size: 24, weight: .bold, role: .accent))
                                .italic()
                                .foregroundStyle(PrototypeTheme.textPrimary)
                                .lineSpacing(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(28)
                                .background(
                                    ZStack {
                                        PrototypeTheme.surface
                                        encounter.track.color.opacity(0.04)
                                    }
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 64)
                    }

                    Spacer(minLength: 160)
                }
            }

            // Action Floating Bar
            VStack {
                Spacer()

                HStack(spacing: 16) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 64, height: 64)
                            .background(
                                LinearGradient(
                                    colors: [encounter.track.color, encounter.track.color.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                            .shadow(color: encounter.track.color.opacity(0.3), radius: 15, x: 0, y: 8)
                    }

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showsLyricModal = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "quote.bubble.fill")
                                .font(.system(size: 16, weight: .bold))
                            Text("歌詞を刻む")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundStyle(PrototypeTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(PrototypeTheme.surfaceElevated)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 8)
                    }

                    Button(action: {
                        showsProfile = true
                    }) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(PrototypeTheme.textPrimary)
                            .frame(width: 64, height: 64)
                            .background(PrototypeTheme.surface)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showsProfile) {
            // This is a placeholder for actual user profile
            Text("Profile View for \(encounter.userName)")
        }
        .sheet(isPresented: $showsLyricModal) {
            LyricInputModalView()
        }
    }
}
