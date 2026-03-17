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

            // 空間を満たすオーラ
            LinearGradient(
                colors: [
                    encounter.track.color.opacity(0.1),
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
                            Image(systemName: "arrow.left") // より情緒的な矢印
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(PrototypeTheme.textPrimary)
                                .frame(width: 44, height: 44, alignment: .leading)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("CONNECTED MOMENT") // 「つながり」の記録
                                .font(PrototypeTheme.Typography.font(size: 10, weight: .black, role: .data))
                                .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.5))
                                .tracking(2.0)

                            Text(encounter.relativeTime.uppercased())
                                .font(PrototypeTheme.Typography.font(size: 12, weight: .bold, role: .data))
                                .foregroundStyle(encounter.track.color)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 24)

                    // Hero: 空間を切り取るジャケット
                    VStack(spacing: 60) {
                        ZStack {
                            // 背景のオーラ
                            Circle()
                                .fill(encounter.track.color.opacity(0.15))
                                .frame(width: 400, height: 400)
                                .blur(radius: 60)

                            MockArtworkView(color: encounter.track.color, symbol: "music.note", size: 300, artwork: encounter.track.artwork)
                                .clipShape(RoundedRectangle(cornerRadius: 48, style: .continuous))
                                .shadow(color: encounter.track.color.opacity(0.2), radius: 60, x: 0, y: 30)
                        }
                        .padding(.top, 40)

                        VStack(spacing: 24) {
                            VStack(spacing: 8) {
                                Text(encounter.userName)
                                    .font(PrototypeTheme.Typography.font(size: 42, weight: .black, role: .primary))
                                    .foregroundStyle(PrototypeTheme.textPrimary)
                                    .tracking(-1.5)
                                
                                Text("との共鳴")
                                    .font(PrototypeTheme.Typography.font(size: 14, weight: .bold))
                                    .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.6))
                            }

                            VStack(spacing: 4) {
                                Text(encounter.track.title)
                                    .font(PrototypeTheme.Typography.font(size: 24, weight: .bold, role: .accent))
                                    .italic()
                                    .foregroundStyle(encounter.track.color)
                                    .multilineTextAlignment(.center)
                                
                                Text(encounter.track.artist)
                                    .font(PrototypeTheme.Typography.font(size: 14, weight: .medium))
                                    .foregroundStyle(PrototypeTheme.textSecondary)
                            }
                        }
                        .padding(.horizontal, 32)
                    }

                    // Shared Memory / Lyric
                    if !encounter.lyric.isEmpty {
                        VStack(alignment: .leading, spacing: 24) {
                            Text("記憶の断片")
                                .font(PrototypeTheme.Typography.font(size: 11, weight: .black, role: .data))
                                .foregroundStyle(encounter.track.color.opacity(0.6))
                                .kerning(3)
                                .padding(.leading, 8)
                            
                            Text(encounter.lyric)
                                .font(PrototypeTheme.Typography.font(size: 28, weight: .medium))
                                .foregroundStyle(PrototypeTheme.textPrimary.opacity(0.9))
                                .lineSpacing(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(40)
                                .background(
                                    ZStack {
                                        // 境界線のない面
                                        Color.white.opacity(0.01)
                                        encounter.track.color.opacity(0.03)
                                    }
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 100)
                    }

                    Spacer(minLength: 200)
                }
            }

            // Floating Action: 最小限に
            VStack {
                Spacer()
                HStack(spacing: 16) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 72, height: 72)
                            .background(
                                Circle()
                                    .fill(encounter.track.color)
                                    .shadow(color: encounter.track.color.opacity(0.3), radius: 20, x: 0, y: 10)
                            )
                    }

                    Button {
                        showsLyricModal = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 18, weight: .bold))
                            Text("想いを刻む")
                                .font(PrototypeTheme.Typography.font(size: 16, weight: .bold))
                        }
                        .foregroundStyle(PrototypeTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 72)
                        .background(
                            Capsule()
                                .fill(PrototypeTheme.surfaceElevated)
                                .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
                        )
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
    }
}
