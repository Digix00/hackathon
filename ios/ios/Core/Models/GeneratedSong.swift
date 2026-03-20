import SwiftUI

struct GeneratedSong: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let color: Color
    let participantCount: Int
    let generatedAt: Date?
    let durationSec: Int?
    let mood: String?
    let myLyric: String?
    let audioURL: String?
    let chainId: String?
    let isLiked: Bool
}
