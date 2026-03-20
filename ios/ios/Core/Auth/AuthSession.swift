import Combine
import Foundation

#if canImport(FirebaseCore)
import FirebaseCore
#endif

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

@MainActor
final class AuthSession: ObservableObject {
    enum Status {
        case checking
        case signedOut
        case signedIn
    }

    @Published private(set) var status: Status
    @Published private(set) var isSigningOut = false
    private var didStart = false

#if canImport(FirebaseAuth)
    private var listenerHandle: AuthStateDidChangeListenerHandle?
#endif

    init() {
        status = .checking
    }

    func startIfNeeded() {
        guard !didStart else { return }
        didStart = true

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

    func signOut() throws {
        guard !isSigningOut else { return }
        isSigningOut = true
        defer { isSigningOut = false }

#if canImport(GoogleSignIn)
        GIDSignIn.sharedInstance.signOut()
#endif

#if canImport(FirebaseAuth) && canImport(FirebaseCore)
        if FirebaseApp.app() != nil, Auth.auth().currentUser != nil {
            try Auth.auth().signOut()
        }
#endif

        status = .signedOut
    }
}
