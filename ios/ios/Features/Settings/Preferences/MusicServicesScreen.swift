import AuthenticationServices
import Combine
import SwiftUI

struct MusicServicesView: View {
    @StateObject private var viewModel = MusicServicesViewModel()
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
                await OAuthSessionCoordinator.shared.start(url: url, callbackScheme: "digix") { callbackURL in
                    if let callbackURL {
                        viewModel.handleCallbackURL(callbackURL)
                    }
                }
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
                errorMessage = "\(provider.title)の認可URLが不正です。設定を確認してください"
                return nil
            }
            return url
        } catch let error as BackendAPIClient.BackendError {
            errorMessage = connectionStartErrorMessage(for: provider, error: error)
        } catch {
            errorMessage = "\(provider.title)の認可URL取得に失敗しました"
            return nil
        }
        return nil
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
        } catch let error as BackendAPIClient.BackendError {
            errorMessage = disconnectErrorMessage(for: provider, error: error)
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
                errorMessage = callbackErrorMessage(for: provider, errorCode: errorCode)
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
        } catch let error as BackendAPIClient.BackendError {
            if Task.isCancelled { return }
            errorMessage = listConnectionsErrorMessage(error)
            hasLoaded = false
            isLoading = false
        } catch {
            if Task.isCancelled { return }
            errorMessage = "連携状況の取得に失敗しました"
            hasLoaded = false
            isLoading = false
        }
    }

    private func connectionStartErrorMessage(
        for provider: MusicConnectionProvider,
        error: BackendAPIClient.BackendError
    ) -> String {
        switch error {
        case .missingAuthToken:
            return "ログイン状態を確認してください。再度ログインしてからお試しください"
        case .invalidBaseURL:
            return "API の接続先が未設定です。`API_BASE_URL` を確認してください"
        case .unexpectedStatus(let status, let body):
            let message = backendMessage(from: body)?.lowercased() ?? ""
            if status == 401 {
                return "認証に失敗しました。再度ログインしてからお試しください"
            }
            if message.contains("oauth is not configured") {
                return "\(provider.title)連携はまだ設定されていません。backend の OAuth 設定を確認してください"
            }
            return "\(provider.title)の認可URL取得に失敗しました"
        case .invalidResponse:
            return "\(provider.title)の認可URL取得結果が不正です"
        }
    }

    private func disconnectErrorMessage(
        for provider: MusicConnectionProvider,
        error: BackendAPIClient.BackendError
    ) -> String {
        switch error {
        case .missingAuthToken:
            return "ログイン状態を確認してください。再度ログインしてからお試しください"
        case .unexpectedStatus(let status, _):
            if status == 404 {
                return "\(provider.title)は未連携です"
            }
            if status == 401 {
                return "認証に失敗しました。再度ログインしてからお試しください"
            }
            return "\(provider.title)の連携解除に失敗しました"
        default:
            return "\(provider.title)の連携解除に失敗しました"
        }
    }

    private func callbackErrorMessage(for provider: MusicConnectionProvider, errorCode: String) -> String {
        switch errorCode {
        case "BAD_REQUEST":
            return "\(provider.title)の連携リクエストが無効です。もう一度やり直してください"
        case "UNAUTHORIZED":
            return "\(provider.title)の認証に失敗しました。再度ログインしてからお試しください"
        case "INTERNAL":
            return "\(provider.title)連携の設定が不足しているか、サーバー側でエラーが発生しました"
        default:
            return "\(provider.title)の連携に失敗しました (\(errorCode))"
        }
    }

    private func listConnectionsErrorMessage(_ error: BackendAPIClient.BackendError) -> String {
        switch error {
        case .missingAuthToken:
            return "ログイン状態を確認してください。再度ログインしてからお試しください"
        case .invalidBaseURL:
            return "API の接続先が未設定です。`API_BASE_URL` を確認してください"
        case .unexpectedStatus(let status, _):
            if status == 401 {
                return "認証に失敗しました。再度ログインしてからお試しください"
            }
            return "連携状況の取得に失敗しました"
        case .invalidResponse:
            return "連携状況の応答形式が不正です"
        }
    }

    private func backendMessage(from body: String?) -> String? {
        guard
            let body,
            let data = body.data(using: .utf8),
            let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let message = payload["message"] as? String,
            !message.isEmpty
        else {
            return nil
        }
        return message
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
