import SwiftUI

struct LibraryFooter: View {
    @Binding var selectedTab: MainPrototypeView.LibraryTab
    @Environment(\.bottomSafeAreaInset) private var bottomSafeArea
    let tabs: [MainPrototypeView.LibraryTab]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.rawValue) { tab in
                Button {
                    HapticsService.impact(.light)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 24, weight: .medium))
                            .symbolRenderingMode(.hierarchical)

                        Text(tab.title)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(selectedTab == tab ? PrototypeTheme.textPrimary : PrototypeTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .background(.thinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(PrototypeTheme.border.opacity(0.5))
                .frame(height: 0.5)
        }
        .padding(.bottom, bottomSafeArea)
        .frame(maxWidth: .infinity)
        .frame(height: 64 + bottomSafeArea, alignment: .top)
    }
}
