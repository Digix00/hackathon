import Combine
import Foundation

#if canImport(FirebaseCore)
import FirebaseCore
#endif

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

@MainActor
final class AuthSession: ObservableObject {
    enum Status {
        case checking
        case signedOut
        case signedIn
    }

    @Published private(set) var status: Status

#if canImport(FirebaseAuth)
    private var listenerHandle: AuthStateDidChangeListenerHandle?
#endif

    init() {
#if canImport(FirebaseAuth) && canImport(FirebaseCore)
        guard FirebaseApp.app() != nil else {
            status = .signedOut
            return
        }

        status = Auth.auth().currentUser == nil ? .signedOut : .signedIn
        listenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            self.status = user == nil ? .signedOut : .signedIn
        }
#else
        status = .signedOut
#endif
    }

    deinit {
#if canImport(FirebaseAuth)
        if let listenerHandle {
            Auth.auth().removeStateDidChangeListener(listenerHandle)
        }
#endif
    }
}
