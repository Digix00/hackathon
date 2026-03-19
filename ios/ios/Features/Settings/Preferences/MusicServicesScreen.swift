import SwiftUI
import Combine

struct MusicServicesView: View {
    @StateObject private var viewModel = MusicServicesViewModel()
    @Environment(\.openURL) private var openURL
    @State private var pendingDisconnectProvider: MusicConnectionProvider?

    var body: some View {
        AppScaffold(
            title: "音楽サービス連携",
            subtitle: "接続中のサービス",
            showsBackButton: true
        ) {
            VStack(spacing: 20) {
                SectionCard {
                    VStack(spacing: 0) {
                        ForEach(Array(MusicConnectionProvider.allCases.enumerated()), id: \.element) { index, provider in
                            Button {
                                handleTap(for: provider)
                            } label: {
                                SettingRow(
                                    icon: provider.iconName,
                                    title: provider.title,
                                    subtitle: subtitle(for: provider)
                                )
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(.plain)
                            .disabled(viewModel.isActionInProgress(provider) || viewModel.isLoading)

                            if index < MusicConnectionProvider.allCases.count - 1 {
                                Divider()
                            }
                        }
                    }
                }

                if viewModel.isLoading || viewModel.isSaving || viewModel.errorMessage != nil {
                    SettingsStatusView(
                        isLoading: viewModel.isLoading,
                        isSaving: viewModel.isSaving,
                        errorMessage: viewModel.errorMessage
                    )
                }

                if let actionMessage = viewModel.actionMessage {
                    Text(actionMessage)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PrototypeTheme.success)
                }

                Text("未接続のサービスをタップすると連携を開始します。接続済みのサービスをタップすると連携を解除します。")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textTertiary)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onAppear { viewModel.loadIfNeeded() }
            .onOpenURL { url in
                viewModel.handleCallbackURL(url)
            }
            .confirmationDialog(
                "連携解除",
                isPresented: Binding(
                    get: { pendingDisconnectProvider != nil },
                    set: { if !$0 { pendingDisconnectProvider = nil } }
                )
            ) {
                if let provider = pendingDisconnectProvider {
                    Button("\(provider.title)の連携を解除", role: .destructive) {
                        pendingDisconnectProvider = nil
                        Task { await viewModel.disconnect(provider) }
                    }
                }
                Button("キャンセル", role: .cancel) {
                    pendingDisconnectProvider = nil
                }
            } message: {
                if let provider = pendingDisconnectProvider {
                    Text("\(provider.title)との連携を解除します。")
                }
            }
        }
    }

    private func handleTap(for provider: MusicConnectionProvider) {
        guard !viewModel.isActionInProgress(provider), !viewModel.isLoading else { return }
        if viewModel.isConnected(provider) {
            pendingDisconnectProvider = provider
            return
        }

        Task {
            if let url = await viewModel.startConnection(for: provider) {
                openURL(url)
            }
        }
    }

    private func subtitle(for provider: MusicConnectionProvider) -> String {
        if viewModel.isConnecting(provider) {
            return "連携中..."
        }
        if viewModel.isDisconnecting(provider) {
            return "解除中..."
        }
        if let connection = viewModel.connection(for: provider) {
            if let username = connection.providerUsername?.trimmingCharacters(in: .whitespacesAndNewlines),
               !username.isEmpty
            {
                return "接続済み · \(username)"
            }
            return "接続済み"
        }
        return "未接続"
    }
}

@MainActor
final class MusicServicesViewModel: ObservableObject {
    enum ActionState: Equatable {
        case connecting(MusicConnectionProvider)
        case disconnecting(MusicConnectionProvider)
    }

    @Published private(set) var connections: [MusicConnectionProvider: BackendMusicConnection] = [:]
    @Published private(set) var isLoading = false
    @Published private(set) var actionMessage: String?
    @Published private(set) var errorMessage: String?
    @Published private(set) var actionState: ActionState?

    private let client: BackendAPIClient
    private var hasLoaded = false
    private var loadTask: Task<Void, Never>?

    init(client: BackendAPIClient = BackendAPIClient()) {
        self.client = client
    }

    var isSaving: Bool {
        actionState != nil
    }

    func loadIfNeeded() {
        guard !hasLoaded else { return }
        refresh()
    }

    func refresh() {
        loadTask?.cancel()
        loadTask = Task { await loadConnections() }
    }

    func isConnected(_ provider: MusicConnectionProvider) -> Bool {
        connections[provider] != nil
    }

    func connection(for provider: MusicConnectionProvider) -> BackendMusicConnection? {
        connections[provider]
    }

    func isActionInProgress(_ provider: MusicConnectionProvider) -> Bool {
        switch actionState {
        case .connecting(let active), .disconnecting(let active):
            return active == provider
        case .none:
            return false
        }
    }

    func isConnecting(_ provider: MusicConnectionProvider) -> Bool {
        actionState == .connecting(provider)
    }

    func isDisconnecting(_ provider: MusicConnectionProvider) -> Bool {
        actionState == .disconnecting(provider)
    }

    func startConnection(for provider: MusicConnectionProvider) async -> URL? {
        guard actionState == nil else { return nil }
        actionMessage = nil
        errorMessage = nil
        actionState = .connecting(provider)
        defer { actionState = nil }

        do {
            let response = try await client.getMusicAuthorizeURL(provider: provider)
            guard let urlString = response.authorizeURL, let url = URL(string: urlString) else {
                errorMessage = "認可URLの取得に失敗しました"
                return nil
            }
            return url
        } catch {
            errorMessage = "認可URLの取得に失敗しました"
            return nil
        }
    }

    func disconnect(_ provider: MusicConnectionProvider) async {
        guard actionState == nil else { return }
        actionMessage = nil
        errorMessage = nil
        actionState = .disconnecting(provider)
        defer { actionState = nil }

        do {
            try await client.deleteMusicConnection(provider: provider)
            connections[provider] = nil
            actionMessage = "\(provider.title)の連携を解除しました"
        } catch {
            errorMessage = "\(provider.title)の連携解除に失敗しました"
        }
    }

    func handleCallbackURL(_ url: URL) {
        guard url.scheme == "digix", url.host == "music-connections" else { return }
        let components = url.pathComponents.filter { $0 != "/" }
        guard components.count >= 2 else { return }
        let rawProvider = components[0]
        guard let provider = MusicConnectionProvider(rawValue: rawProvider) else { return }

        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let result = queryItems.first(where: { $0.name == "result" })?.value
        let errorCode = queryItems.first(where: { $0.name == "error_code" })?.value

        if result == "success" {
            errorMessage = nil
            actionMessage = "\(provider.title)の連携が完了しました"
            refresh()
        } else if result == "error" {
            actionMessage = nil
            if let errorCode, !errorCode.isEmpty {
                errorMessage = "\(provider.title)の連携に失敗しました (\(errorCode))"
            } else {
                errorMessage = "\(provider.title)の連携に失敗しました"
            }
        }
    }

    private func loadConnections() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await client.listMusicConnections()
            if Task.isCancelled { return }
            var mapped: [MusicConnectionProvider: BackendMusicConnection] = [:]
            response.forEach { connection in
                guard let rawProvider = connection.provider,
                      let provider = MusicConnectionProvider(rawValue: rawProvider)
                else { return }
                mapped[provider] = connection
            }
            connections = mapped
            hasLoaded = true
            isLoading = false
        } catch {
            if Task.isCancelled { return }
            errorMessage = "連携状況の取得に失敗しました"
            hasLoaded = false
            isLoading = false
        }
    }
}

private extension MusicConnectionProvider {
    var title: String {
        switch self {
        case .spotify:
            return "Spotify"
        case .appleMusic:
            return "Apple Music"
        }
    }

    var iconName: String {
        switch self {
        case .spotify:
            return "music.note.list"
        case .appleMusic:
            return "music.note.house"
        }
    }
}
