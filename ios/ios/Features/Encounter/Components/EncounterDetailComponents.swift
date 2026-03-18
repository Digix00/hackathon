import SwiftUI

struct EncounterMatchedArtworkView: View {
    let encounter: Encounter
    let size: CGFloat
    let shadowOpacity: CGFloat
    let shadowRadius: CGFloat
    let shadowYOffset: CGFloat
    let namespace: Namespace.ID?

    var body: some View {
        Group {
            if let namespace {
                artworkView
                    .matchedGeometryEffect(id: "artwork-\(encounter.id)", in: namespace)
            } else {
                artworkView
            }
        }
        .shadow(
            color: encounter.track.color.opacity(shadowOpacity),
            radius: shadowRadius,
            x: 0,
            y: shadowYOffset
        )
    }

    private var artworkView: some View {
        MockArtworkView(
            color: encounter.track.color,
            symbol: "music.note",
            size: size,
            artwork: encounter.track.artwork
        )
    }
}

struct EncounterMatchedUserNameView: View {
    let encounter: Encounter
    let fontSize: CGFloat
    let namespace: Namespace.ID?

    var body: some View {
        Group {
            if let namespace {
                Text(encounter.userName)
                    .matchedGeometryEffect(id: "userName-\(encounter.id)", in: namespace)
            } else {
                Text(encounter.userName)
            }
        }
        .font(PrototypeTheme.Typography.font(size: fontSize, weight: .black, role: .primary))
        .foregroundStyle(PrototypeTheme.textPrimary)
        .tracking(-1.5)
    }
}

struct EncounterMatchedTrackTitleView: View {
    let encounter: Encounter
    let fontSize: CGFloat
    let namespace: Namespace.ID?

    var body: some View {
        Group {
            if let namespace {
                Text(encounter.track.title)
                    .matchedGeometryEffect(id: "trackTitle-\(encounter.id)", in: namespace)
            } else {
                Text(encounter.track.title)
            }
        }
        .font(PrototypeTheme.Typography.font(size: fontSize, weight: .bold, role: .accent))
        .italic()
        .foregroundStyle(encounter.track.color)
    }
}

struct EncounterDetailHeader: View {
    let encounter: Encounter
    let isVisible: Bool
    let topInset: CGFloat
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(PrototypeTheme.textPrimary)
                    .frame(width: 44, height: 44, alignment: .leading)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("CONNECTED MOMENT")
                    .font(PrototypeTheme.Typography.font(size: 10, weight: .black, role: .data))
                    .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.5))
                    .tracking(2.0)

                Text(encounter.relativeTime.uppercased())
                    .font(PrototypeTheme.Typography.font(size: 12, weight: .bold, role: .data))
                    .foregroundStyle(encounter.track.color)
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, topInset + 24)
        .opacity(isVisible ? 1 : 0)
    }
}

struct EncounterLyricSection: View {
    let encounter: Encounter

    var body: some View {
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
                            Color.white.opacity(0.01)
                            encounter.track.color.opacity(0.03)
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            }
            .padding(.horizontal, 24)
            .padding(.top, 100)
        }
    }
}

struct EncounterPrimaryActions: View {
    let encounter: Encounter
    let onWriteLyric: () -> Void

    var body: some View {
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

            Button(action: onWriteLyric) {
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
    }
}
