import SwiftUI

struct GeneratedSongRow: View {
    let song: GeneratedSong
    let hideMatchedElements: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.encounterNamespace) private var namespace

    init(song: GeneratedSong, hideMatchedElements: Bool = false) {
        self.song = song
        self.hideMatchedElements = hideMatchedElements
    }
    
    private var seed: Int {
        let magnitude = song.id.hashValue.magnitude
        return Int(magnitude % UInt(Int.max))
    }

    // --- Dynamic Design Engine (Adapted for Songs) ---

    private var horizontalShift: CGFloat {
        let baseShift = CGFloat(seed % 40) - 20
        return baseShift * 1.2
    }

    private var artworkOffset: (x: CGFloat, y: CGFloat) {
        let xOffset: CGFloat = horizontalShift > 0 ? -140 : 140
        return (xOffset, -10)
    }

    private var metadataOffset: CGFloat {
        return -horizontalShift * 0.5
    }

    var body: some View {
        ZStack(alignment: .center) {
            // Background Aura
            auraView

            VStack(alignment: .center, spacing: 0) {
                
                // Metadata
                HStack(alignment: .center, spacing: 12) {
                    Text("GENERATED SONG")
                        .font(PrototypeTheme.Typography.font(size: 10, weight: .black, role: .data))
                        .kerning(2)
                        .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.4))
                    
                    Rectangle()
                        .fill(song.color.opacity(0.2))
                        .frame(width: 30, height: 1)
                }
                .padding(.bottom, 24)
                .offset(x: metadataOffset)

                // Main Composition
                ZStack(alignment: .center) {
                    
                    // Artwork
                    Group {
                        if let namespace = namespace, !hideMatchedElements {
                            artworkView(size: 84)
                                .matchedGeometryEffect(id: "song-artwork-\(song.id)", in: namespace, isSource: true)
                        } else {
                            artworkView(size: 84)
                                .opacity(hideMatchedElements ? 0 : 1)
                        }
                    }
                    .offset(x: artworkOffset.x, y: artworkOffset.y)
                    .rotationEffect(.degrees(Double(horizontalShift) / 1.5))
                    
                    // Song Info
                    VStack(alignment: horizontalShift > 0 ? .leading : .trailing, spacing: 6) {
                        Group {
                            if let namespace = namespace, !hideMatchedElements {
                                Text(song.title)
                                    .matchedGeometryEffect(id: "song-title-\(song.id)", in: namespace, isSource: true)
                            } else {
                                Text(song.title)
                                    .opacity(hideMatchedElements ? 0 : 1)
                            }
                        }
                        .font(PrototypeTheme.Typography.font(size: 32, weight: .black, role: .primary))
                        .foregroundStyle(PrototypeTheme.textPrimary)
                        .tracking(-1.0)
                        .lineLimit(2)
                        .multilineTextAlignment(horizontalShift > 0 ? .leading : .trailing)

                        Group {
                            if let namespace = namespace, !hideMatchedElements {
                                Text(song.subtitle)
                                    .matchedGeometryEffect(id: "song-subtitle-\(song.id)", in: namespace, isSource: true)
                            } else {
                                Text(song.subtitle)
                                    .opacity(hideMatchedElements ? 0 : 1)
                            }
                        }
                        .font(PrototypeTheme.Typography.font(size: 14, weight: .bold, role: .accent))
                        .foregroundStyle(song.color)
                    }
                    .frame(width: 220, alignment: horizontalShift > 0 ? .leading : .trailing)
                    .offset(x: horizontalShift)
                }
                .padding(.bottom, 32)

                // The Echo (My Lyric)
                if let myLyric = song.myLyric, !myLyric.isEmpty {
                    Text("“\(myLyric)”")
                        .font(PrototypeTheme.Typography.font(size: 16, weight: .medium))
                        .foregroundStyle(PrototypeTheme.textPrimary.opacity(0.7))
                        .italic()
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 280)
                        .offset(x: -horizontalShift * 0.3)
                }
            }
            .padding(.vertical, 60)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.001))
    }

    private func artworkView(size: CGFloat) -> some View {
        ZStack {
            MockArtworkView(color: song.color, symbol: "waveform", size: size)
            
            if song.audioURL == nil {
                Image(systemName: "clock.fill")
                    .font(.system(size: size * 0.3, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Circle())
                    .offset(x: size * 0.35, y: -size * 0.35)
            }
        }
        .shadow(color: song.color.opacity(0.15), radius: 25, x: 0, y: 12)
    }

    private var auraView: some View {
        let interval = reduceMotion ? 1.0 / 10.0 : 1.0 / 20.0

        return TimelineView(.animation(minimumInterval: interval)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let seedPhase = Double(seed % 11) * 0.37
            let driftX = CGFloat(sin(t * 0.6 + seedPhase) * 40)
            let driftY = CGFloat(cos(t * 0.5 + seedPhase * 1.2) * 25)
            let pulse = 1 + CGFloat(sin(t * 0.65 + seedPhase) * 0.1)

            ZStack {
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                song.color.opacity(0.35),
                                song.color.opacity(0.12),
                                .clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 160
                        )
                    )
                    .frame(width: 320, height: 260)
                    .scaleEffect(pulse)
                    .blur(radius: 60)
                    .offset(x: horizontalShift * 1.5 + driftX, y: driftY)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                song.color.opacity(0.25),
                                song.color.opacity(0.08),
                                .clear
                            ],
                            center: .center,
                            startRadius: 5,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(pulse * 0.9)
                    .blur(radius: 40)
                    .offset(x: horizontalShift * 1.0 - driftX * 0.5, y: -20 + driftY * 0.8)
            }
            .saturation(1.1)
        }
    }
}
