import SwiftUI

// MARK: - Home Namespace Key

struct HomeNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID = Namespace().wrappedValue
}

extension EnvironmentValues {
    var homeNamespace: Namespace.ID {
        get { self[HomeNamespaceKey.self] }
        set { self[HomeNamespaceKey.self] = newValue }
    }
}

// MARK: - Encounter Namespace Key

struct EncounterNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    var encounterNamespace: Namespace.ID? {
        get { self[EncounterNamespaceKey.self] }
        set { self[EncounterNamespaceKey.self] = newValue }
    }
}

// MARK: - Safe Area Inset Keys

struct TopSafeAreaInsetKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

struct BottomSafeAreaInsetKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var topSafeAreaInset: CGFloat {
        get { self[TopSafeAreaInsetKey.self] }
        set { self[TopSafeAreaInsetKey.self] = newValue }
    }

    var bottomSafeAreaInset: CGFloat {
        get { self[BottomSafeAreaInsetKey.self] }
        set { self[BottomSafeAreaInsetKey.self] = newValue }
    }
}
