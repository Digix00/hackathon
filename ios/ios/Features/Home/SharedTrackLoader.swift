import Combine
import SwiftUI

@MainActor
final class SharedTrackLoader: ObservableObject {
    @Published private(set) var track: Track?

    private let client: BackendAPIClient
    private var isLoading = false

    init(client: BackendAPIClient = BackendAPIClient()) {
        self.client = client
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            if let shared = try await client.getSharedTrack() {
                var mapped = mapTrack(shared)
                if let extracted = await ArtworkColorExtractor.shared.extractColor(from: mapped.artwork) {
                    mapped = mapped.withColor(extracted)
                }
                track = mapped
            } else {
                track = nil
            }
        } catch {
            // ホーム画面のフィーチャードトラックは非致命的 — サイレントに維持
        }
    }

    private func mapTrack(_ t: BackendSharedTrack) -> Track {
        Track(
            title: t.title,
            artist: t.artistName,
            color: paletteColor(for: t.id),
            artwork: t.artworkURL,
            backendId: t.id
        )
    }

    private func paletteColor(for key: String) -> Color {
        let palette: [Color] = [.indigo, .orange, .teal, .pink, .red, .green, .purple, .blue, .mint]
        let index = Int(UInt(bitPattern: key.hashValue) % UInt(palette.count))
        return palette[index]
    }
}
