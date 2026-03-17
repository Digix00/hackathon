import SwiftUI

struct EncounterAvatarView: View {
    let userName: String
    let color: Color
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.8), color],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: color.opacity(0.2), radius: 10, x: 0, y: 5)

            Text(String(userName.prefix(1)).uppercased())
                .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}
