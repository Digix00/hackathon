import SwiftUI

struct OtherUserProfileCard: View {
    let displayName: String
    let bio: String
    let avatarURL: String?
    let sharedTrack: Track?

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
                    SecondaryButton(title: "ミュート", systemImage: "speaker.slash.fill") {}
                    SecondaryButton(title: "通報", systemImage: "flag.fill") {}
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
