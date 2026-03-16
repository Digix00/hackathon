import Foundation

enum BLETokenStore {
    private static let key = "ble.advertising.token"

    static func loadOrCreateToken() -> String {
        let defaults = UserDefaults.standard
        if let existing = defaults.string(forKey: key), !existing.isEmpty {
            return String(existing.prefix(BLEManager.Constants.maxTokenLength))
        }

        let generated = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(BLEManager.Constants.maxTokenLength))
        defaults.set(generated, forKey: key)
        return generated
    }
}
