import SwiftUI

struct BlockMuteListView: View {
    @StateObject private var viewModel = BlockMuteListViewModel()

    var body: some View {
        AppScaffold(
            title: "ブロック / ミュート",
            subtitle: "公開範囲を調整",
            showsBackButton: true
        ) {
            VStack(spacing: 24) {
                SectionCard(title: "ブロック") {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("ブロックするユーザーID", text: $viewModel.blockUserID)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(14)
                            .background(PrototypeTheme.surfaceMuted)
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        HStack(spacing: 12) {
                            PrimaryButton(
                                title: viewModel.isBlocking ? "ブロック中..." : "ブロック",
                                systemImage: "hand.raised.fill",
                                isDisabled: viewModel.isBlockActionInProgress || viewModel.blockUserID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ) {
                                viewModel.block()
                            }

                            SecondaryButton(
                                title: viewModel.isUnblocking ? "解除中..." : "ブロック解除",
                                systemImage: "hand.raised.slash.fill"
                            ) {
                                viewModel.unblock()
                            }
                            .disabled(viewModel.isBlockActionInProgress || viewModel.blockUserID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }

                        if let blockMessage = viewModel.blockMessage {
                            Text(blockMessage)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(PrototypeTheme.success)
                        }

                        if let blockErrorMessage = viewModel.blockErrorMessage {
                            Text(blockErrorMessage)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(PrototypeTheme.error)
                        }

                        Divider()
                            .opacity(0.4)

                        if viewModel.isLoadingBlocks && viewModel.blockedUsers.isEmpty {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else if viewModel.blockedUsers.isEmpty {
                            Text("ブロック中のユーザーはいません")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                        } else {
                            ForEach(viewModel.blockedUsers) { user in
                                HStack {
                                    Text(user.blockedUserId)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(PrototypeTheme.textPrimary)
                                    Spacer()
                                    Button {
                                        viewModel.unblock(userID: user.blockedUserId)
                                    } label: {
                                        Image(systemName: "hand.raised.slash.fill")
                                            .foregroundStyle(PrototypeTheme.error)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(viewModel.isBlockActionInProgress)
                                }
                                .padding(.vertical, 6)
                            }
                        }

                        if let listErrorMessage = viewModel.blockListErrorMessage {
                            Text(listErrorMessage)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(PrototypeTheme.error)
                        }
                    }
                }
                SectionCard(title: "ミュート") {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("ミュートするユーザーID", text: $viewModel.muteUserID)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(14)
                            .background(PrototypeTheme.surfaceMuted)
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        HStack(spacing: 12) {
                            PrimaryButton(
                                title: viewModel.isMuting ? "ミュート中..." : "ミュート",
                                systemImage: "speaker.slash.fill",
                                isDisabled: viewModel.isMuteActionInProgress || viewModel.muteUserID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ) {
                                viewModel.mute()
                            }

                            SecondaryButton(
                                title: viewModel.isUnmuting ? "解除中..." : "ミュート解除",
                                systemImage: "speaker.wave.2.fill"
                            ) {
                                viewModel.unmute()
                            }
                            .disabled(viewModel.isMuteActionInProgress || viewModel.muteUserID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }

                        if let muteMessage = viewModel.muteMessage {
                            Text(muteMessage)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(PrototypeTheme.success)
                        }

                        if let muteErrorMessage = viewModel.muteErrorMessage {
                            Text(muteErrorMessage)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(PrototypeTheme.error)
                        }

                        Divider()
                            .opacity(0.4)

                        if viewModel.isLoadingMutes && viewModel.mutedUsers.isEmpty {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else if viewModel.mutedUsers.isEmpty {
                            Text("ミュート中のユーザーはいません")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                        } else {
                            ForEach(viewModel.mutedUsers) { user in
                                HStack {
                                    Text(user.targetUserId)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(PrototypeTheme.textPrimary)
                                    Spacer()
                                    Button {
                                        viewModel.unmute(userID: user.targetUserId)
                                    } label: {
                                        Image(systemName: "speaker.wave.2.fill")
                                            .foregroundStyle(PrototypeTheme.error)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(viewModel.isMuteActionInProgress)
                                }
                                .padding(.vertical, 6)
                            }
                        }

                        if let listErrorMessage = viewModel.muteListErrorMessage {
                            Text(listErrorMessage)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(PrototypeTheme.error)
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.refresh()
        }
    }
}
