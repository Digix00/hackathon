import SwiftUI

struct GeneratedSong: Identifiable, Hashable {
    var id: String { "\(title)-\(subtitle)" }
    let title: String
    let subtitle: String
    let color: Color
}
