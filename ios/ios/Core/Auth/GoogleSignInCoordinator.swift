import Foundation

#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

enum GoogleSignInCoordinator {
    static func handle(url: URL) -> Bool {
#if canImport(GoogleSignIn)
        return GIDSignIn.sharedInstance.handle(url)
#else
        return false
#endif
    }
}
