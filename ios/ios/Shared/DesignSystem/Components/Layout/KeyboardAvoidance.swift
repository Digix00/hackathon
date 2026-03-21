import Combine
import SwiftUI
import UIKit

private final class KeyboardObserver: ObservableObject {
    @Published private(set) var endFrame: CGRect = .null
    @Published private(set) var animationDuration: Double = 0.25

    private var cancellables = Set<AnyCancellable>()

    init(center: NotificationCenter = .default) {
        center.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .merge(with: center.publisher(for: UIResponder.keyboardWillHideNotification))
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                self?.handle(notification)
            }
            .store(in: &cancellables)
    }

    private func handle(_ notification: Notification) {
        let userInfo = notification.userInfo ?? [:]
        if let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
            animationDuration = duration
        }

        if notification.name == UIResponder.keyboardWillHideNotification {
            endFrame = .null
            return
        }

        if let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            endFrame = frame
        }
    }
}

private struct GlobalFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

private struct KeyboardAvoidanceModifier: ViewModifier {
    let active: Bool
    let padding: CGFloat

    @StateObject private var keyboard = KeyboardObserver()
    @State private var globalFrame: CGRect = .zero

    private var overlap: CGFloat {
        guard active, !keyboard.endFrame.isNull, keyboard.endFrame.minY > 0 else { return 0 }
        return max(0, globalFrame.maxY + padding - keyboard.endFrame.minY)
    }

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: GlobalFramePreferenceKey.self, value: proxy.frame(in: .global))
                }
            )
            .onPreferenceChange(GlobalFramePreferenceKey.self) { frame in
                globalFrame = frame
            }
            .offset(y: -overlap)
            .animation(.easeOut(duration: keyboard.animationDuration), value: overlap)
    }
}

extension View {
    func keyboardAvoiding(active: Bool = true, padding: CGFloat = 12) -> some View {
        modifier(KeyboardAvoidanceModifier(active: active, padding: padding))
    }
}
