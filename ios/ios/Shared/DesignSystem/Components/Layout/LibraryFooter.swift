import SwiftUI

struct LibraryFooter: View {
    @Binding var selectedTab: MainPrototypeView.LibraryTab
    @Environment(\.bottomSafeAreaInset) private var bottomSafeArea
    let tabs: [MainPrototypeView.LibraryTab]
    
    @Namespace private var animation

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ForEach(tabs, id: \.rawValue) { tab in
                    let isActive = selectedTab == tab
                    
                    Button {
                        HapticsService.impact(.medium)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 4) {
                            ZStack {
                                if isActive {
                                    Circle()
                                        .fill(PrototypeTheme.textPrimary.opacity(0.06))
                                        .frame(width: 48, height: 48)
                                        .matchedGeometryEffect(id: "bg", in: animation)
                                }
                                
                                Image(systemName: isActive ? tab.symbol : tab.symbol)
                                    .font(.system(size: 20, weight: isActive ? .bold : .medium))
                                    .symbolVariant(isActive ? .fill : .none)
                                    .foregroundStyle(isActive ? PrototypeTheme.textPrimary : PrototypeTheme.textSecondary.opacity(0.6))
                            }
                            .frame(width: 48, height: 48)

                            if isActive {
                                Text(tab.title)
                                    .font(PrototypeTheme.Typography.font(size: 10, weight: .bold, role: .data))
                                    .foregroundStyle(PrototypeTheme.textPrimary)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
            )
            .padding(.horizontal, 24)
            .padding(.bottom, bottomSafeArea > 0 ? max(10, bottomSafeArea - 18) : 16)
        }
        .frame(maxWidth: .infinity)
        .ignoresSafeArea(.all, edges: .bottom)
    }
}
