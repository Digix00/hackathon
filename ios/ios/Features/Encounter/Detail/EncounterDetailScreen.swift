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
                    encounter.track.color.opacity(0.15),
                    PrototypeTheme.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    HStack(alignment: .top) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(PrototypeTheme.textPrimary)
                                .frame(width: 44, height: 44, alignment: .leading)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("ENCOUNTERED")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.5))
                                .kerning(2.5)

                            Text(encounterMetaText)
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(encounter.track.color)
                                .kerning(1.0)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    VStack(spacing: 48) {
                        MockArtworkView(color: encounter.track.color, symbol: "music.note", size: 280, artwork: encounter.track.artwork)
                            .shadow(color: encounter.track.color.opacity(0.3), radius: 60, x: 0, y: 30)
                            .padding(.top, 32)

                        VStack(spacing: 12) {
                            Text(encounter.track.title)
                                .font(.system(size: 42, weight: .black))
                                .foregroundStyle(PrototypeTheme.textPrimary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .tracking(-1.5)

                            Text(encounter.track.artist)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                                .tracking(1.2)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .padding(.horizontal, 32)
                    }

                    Button {
                        showsProfile = true
                    } label: {
                        HStack(spacing: 16) {
                            MockArtworkView(color: .gray.opacity(0.2), symbol: "person.fill", size: 36)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text("SHARED BY")
                                    .font(.system(size: 9, weight: .heavy))
                                    .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.5))
                                    .kerning(1.5)

                                Text(encounter.userName)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(PrototypeTheme.textPrimary)
                            }

                            Spacer()

                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(PrototypeTheme.textTertiary)
                        }
                        .padding(16)
                        .background(PrototypeTheme.surface.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 28)
                    .padding(.top, 56)

                    if !encounter.lyric.isEmpty {
                        VStack(alignment: .leading, spacing: 24) {
                            Image(systemName: "quote.opening")
                                .font(.system(size: 32, weight: .black))
                                .foregroundStyle(encounter.track.color.opacity(0.2))
                                .offset(x: -12)

                            Text(encounter.lyric)
                                .font(.system(size: 28, weight: .bold, design: .serif))
                                .italic()
                                .foregroundStyle(PrototypeTheme.textPrimary)
                                .lineSpacing(8)
                                .padding(.horizontal, 16)

                            HStack {
                                Spacer()
                                Image(systemName: "quote.closing")
                                    .font(.system(size: 32, weight: .black))
                                    .foregroundStyle(encounter.track.color.opacity(0.2))
                                    .offset(x: 12)
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 64)
                    }

                    Spacer(minLength: 140)
                }
            }

            VStack {
                Spacer()

                HStack(spacing: 16) {
                    Button(action: {}) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 64, height: 64)
                            .background(encounter.track.color)
                            .clipShape(Circle())
                            .shadow(color: encounter.track.color.opacity(0.4), radius: 20, x: 0, y: 10)
                    }

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showsLyricModal = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .bold))
                            Text("歌詞を残す")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundStyle(PrototypeTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(PrototypeTheme.surfaceElevated)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                    }

                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(PrototypeTheme.textPrimary)
                            .frame(width: 64, height: 64)
                            .background(PrototypeTheme.surface)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showsProfile) {
            OtherUserProfileView()
        }
        .sheet(isPresented: $showsLyricModal) {
            LyricInputModalView()
        }
    }

    private var encounterMetaText: String {
        "\(encounter.relativeTime.uppercased()) • SHIBUYA"
    }
}
