import SwiftUI

struct GeneratedSong: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let color: Color
    let participantCount: Int
    let generatedAt: Date?
    let myLyric: String?
    let audioURL: String?
    let chainId: String?
    let isLiked: Bool
}
