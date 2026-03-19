import SwiftUI

struct OtherUserProfileCard: View {
    let displayName: String
    let bio: String
    let avatarURL: String?
    let sharedTrack: Track?
    let onMute: () -> Void
    let onBlock: () -> Void
    var onReport: () -> Void = {}
    var isMuteDisabled: Bool = false
    var isBlockDisabled: Bool = false
    var isReportDisabled: Bool = false

    var body: some View {
        SectionCard {
            VStack(spacing: 24) {
                UserAvatarView(avatarURL: avatarURL, size: 90, iconSize: 40)

                VStack(spacing: 8) {
                    Text(displayName)
                        .font(.system(size: 24, weight: .black))
                    Text(bio)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(PrototypeTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                if let sharedTrack {
                    TrackSelectionRow(track: sharedTrack)
                }

                HStack(spacing: 12) {
                    SecondaryButton(title: "ミュート", systemImage: "speaker.slash.fill") {
                        onMute()
                    }
                    .disabled(isMuteDisabled)
                    SecondaryButton(title: "ブロック", systemImage: "hand.raised.fill") {
                        onBlock()
                    }
                    .disabled(isBlockDisabled)
                    SecondaryButton(title: "通報", systemImage: "flag.fill") {
                        onReport()
                    }
                    .disabled(isReportDisabled)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

private struct UserAvatarView: View {
    let avatarURL: String?
    let size: CGFloat
    let iconSize: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(PrototypeTheme.surfaceElevated)
                .frame(width: size, height: size)

            if let avatarURL, let url = URL(string: avatarURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.fill")
                        .font(.system(size: iconSize))
                        .foregroundStyle(PrototypeTheme.textTertiary)
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: iconSize))
                    .foregroundStyle(PrototypeTheme.textTertiary)
            }
        }
    }
}
