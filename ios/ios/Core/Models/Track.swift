import SwiftUI

struct Track: Identifiable, Hashable {
    var id: String { "\(title)-\(artist)" }
    let title: String
    let artist: String
    let color: Color
}
