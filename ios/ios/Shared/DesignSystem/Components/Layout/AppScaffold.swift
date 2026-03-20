import SwiftUI

struct AppScaffold<Content: View>: View {
    let title: String
    let subtitle: String?
    let showsBackButton: Bool
    let trailingSymbol: String?
    let accentColor: Color?
    let customBackground: AnyView?
    @ViewBuilder var content: Content

    @Environment(\.dismiss) private var dismiss
    @Environment(\.topSafeAreaInset) private var envTopSafeArea
    @Environment(\.bottomSafeAreaInset) private var envBottomSafeArea

    init(
        title: String,
        subtitle: String? = nil,
        showsBackButton: Bool = false,
        trailingSymbol: String? = nil,
        accentColor: Color? = nil,
        customBackground: AnyView? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showsBackButton = showsBackButton
        self.trailingSymbol = trailingSymbol
        self.accentColor = accentColor
        self.customBackground = customBackground
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            let globalWidth = geometry.frame(in: .global).width
            let layoutWidth = globalWidth > 0 ? min(geometry.size.width, globalWidth) : geometry.size.width
            let topPadding = (envTopSafeArea > 0 ? envTopSafeArea : geometry.safeAreaInsets.top)
            let bottomPadding = (envBottomSafeArea > 0 ? envBottomSafeArea : geometry.safeAreaInsets.bottom)

            ZStack {
                if let customBackground {
                    customBackground
                } else if let accentColor {
                    DynamicBackground(baseColor: accentColor)
                } else {
                    ZStack {
                        PrototypeTheme.background.ignoresSafeArea()
                        DotGridBackground()
                            .opacity(0.15)
                    }
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        Color.clear
                            .frame(height: topPadding)

                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 8) {
                                if showsBackButton {
                                    Button {
                                        dismiss()
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "chevron.left")
                                            Text("戻る")
                                        }
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(PrototypeTheme.textPrimary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(PrototypeTheme.surface.opacity(0.92))
                                        .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.bottom, 8)
                                }

                                Text(title)
                                    .font(PrototypeTheme.Typography.Product.screenTitle)
                                    .foregroundStyle(PrototypeTheme.textPrimary)
                                    .tracking(-0.5)

                                if let subtitle {
                                    Text(subtitle)
                                        .font(PrototypeTheme.Typography.Product.subtitle)
                                        .foregroundStyle(PrototypeTheme.textSecondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(PrototypeTheme.surfaceMuted.opacity(0.6))
                                        .clipShape(Capsule())
                                }
                            }
                            Spacer()
                            if let trailingSymbol {
                                Button(action: {}) {
                                    Image(systemName: trailingSymbol)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(PrototypeTheme.textPrimary)
                                        .padding(12)
                                        .background(PrototypeTheme.surface)
                                        .clipShape(Circle())
                                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                                }
                            }
                        }

                        content
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, max(24, bottomPadding + 8))
                    .frame(width: layoutWidth)
                }
                .scrollContentBackground(.hidden)
            }
            .frame(width: layoutWidth, height: geometry.size.height)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .toolbar(.hidden, for: .navigationBar)
            .background(Color.clear)
            .ignoresSafeArea()
        }
        .if(showsBackButton) { view in
            view.lockLibraryPageSwipe()
        }
        .if(showsBackButton) { view in
            view.disableInteractivePopGesture(true)
        }
    }
}
