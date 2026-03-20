import SwiftUI
import UIKit
import Combine

extension View {
    /// 条件に応じてmodifierを適用する
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// オプショナル値に応じてmodifierを適用する
    @ViewBuilder
    func ifLet<T, Transform: View>(_ value: T?, transform: (Self, T) -> Transform) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }

    func lockLibraryPageSwipe() -> some View {
        modifier(LibraryPageSwipeLockModifier())
    }

    func disablePageTabSwipe(_ isDisabled: Bool) -> some View {
        modifier(PageTabSwipeDisabledModifier(isDisabled: isDisabled))
    }

    func disableInteractivePopGesture(_ isDisabled: Bool) -> some View {
        modifier(InteractivePopGestureDisabledModifier(isDisabled: isDisabled))
    }
}

@MainActor
final class LibraryPageSwipeController: ObservableObject {
    @Published private(set) var isLocked = false

    private var activeTokens: Set<UUID> = []

    func lock(_ token: UUID) {
        activeTokens.insert(token)
        isLocked = !activeTokens.isEmpty
    }

    func unlock(_ token: UUID) {
        activeTokens.remove(token)
        isLocked = !activeTokens.isEmpty
    }
}

private struct LibraryPageSwipeControllerKey: EnvironmentKey {
    static let defaultValue: LibraryPageSwipeController? = nil
}

extension EnvironmentValues {
    var libraryPageSwipeController: LibraryPageSwipeController? {
        get { self[LibraryPageSwipeControllerKey.self] }
        set { self[LibraryPageSwipeControllerKey.self] = newValue }
    }
}

private struct LibraryPageSwipeLockModifier: ViewModifier {
    @Environment(\.libraryPageSwipeController) private var controller
    @State private var token = UUID()

    func body(content: Content) -> some View {
        content
            .onAppear {
                controller?.lock(token)
            }
            .onDisappear {
                controller?.unlock(token)
            }
    }
}

private struct PageTabSwipeDisabledModifier: ViewModifier {
    let isDisabled: Bool

    func body(content: Content) -> some View {
        content.background(
            PagingScrollViewResolver(isDisabled: isDisabled)
                .allowsHitTesting(false)
        )
    }
}

private struct InteractivePopGestureDisabledModifier: ViewModifier {
    let isDisabled: Bool

    func body(content: Content) -> some View {
        content.background(
            NavigationControllerResolver(isDisabled: isDisabled)
                .allowsHitTesting(false)
        )
    }
}

private struct PagingScrollViewResolver: UIViewRepresentable {
    let isDisabled: Bool

    func makeUIView(context: Context) -> UIView {
        UIView(frame: .zero)
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            guard let window = uiView.window ?? uiView.closestWindow() else { return }
            let pagingScrollViews = window.allPagingScrollViews()
            pagingScrollViews.forEach { scrollView in
                scrollView.isScrollEnabled = !isDisabled
                scrollView.panGestureRecognizer.isEnabled = !isDisabled
            }
        }
    }
}

private struct NavigationControllerResolver: UIViewControllerRepresentable {
    let isDisabled: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        ResolverViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            uiViewController.navigationController?.interactivePopGestureRecognizer?.isEnabled = !isDisabled
        }
    }

    private final class ResolverViewController: UIViewController {}
}

private extension UIView {
    func closestWindow() -> UIWindow? {
        if let window {
            return window
        }

        var current = superview
        while let view = current {
            if let window = view as? UIWindow {
                return window
            }
            current = view.superview
        }

        return nil
    }

    func allPagingScrollViews() -> [UIScrollView] {
        var results: [UIScrollView] = []

        if let scrollView = self as? UIScrollView, scrollView.isPagingEnabled {
            results.append(scrollView)
        }

        for subview in subviews {
            results.append(contentsOf: subview.allPagingScrollViews())
        }

        return results
    }
}
