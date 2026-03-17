import SwiftUI

struct Track: Identifiable, Hashable {
    var id: String { "\(title)-\(artist)" }
    let title: String
    let artist: String
    let color: Color
    let artwork: String?

    init(title: String, artist: String, color: Color, artwork: String? = nil) {
        self.title = title
        self.artist = artist
        self.color = color
        self.artwork = artwork
    }
}
