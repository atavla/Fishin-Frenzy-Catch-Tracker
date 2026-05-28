import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var confirmClear = false

    var body: some View {
        ZStack
        {
            OceanBackground(assetName: "catch_button_wood_texture")
            
            Group {
                if viewModel.sessions.isEmpty {
                    EmptyStateView(title: "Keepnet Empty", message: "Finished expeditions will appear here as a chronological feed.", systemImage: "tray", actionTitle: "Start Fishing") {
                        viewModel.selectedTab = .setup
                    }
                } else {
                    List {
                        ForEach(viewModel.sessions) { session in
                            SessionCard(session: session)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: viewModel.deleteSessions)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Fishing Catch")
            .toolbar {
                if !viewModel.sessions.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear", role: .destructive) {
                            confirmClear = true
                        }
                    }
                }
            }
            .confirmationDialog("Clear archive?", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("Delete All Records", role: .destructive) {
                    viewModel.clearHistory()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
}

private struct SessionCard: View {
    let session: FishingSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.setup.location)
                        .font(.headline)
                    Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(session.netResult.currencyString)
                    .font(.title3.monospacedDigit().bold())
                    .foregroundStyle(session.netResult >= 0 ? Color.appSuccess : Color.red)
            }

            HStack(spacing: 10) {
                Label {
                    Text(durationText)
                } icon: {
                    AssetIcon(name: "icon_timer", size: 18, fallbackSystemImage: "timer")
                }
                Label {
                    Text("\(session.bonusCount) bonuses")
                } icon: {
                    AssetIcon(name: "icon_scatter_boat", size: 18, fallbackSystemImage: "sailboat")
                }
                Label {
                    Text("max \(session.maxCatch.currencyString)")
                } icon: {
                    AssetIcon(name: "icon_small_fish", size: 18, fallbackSystemImage: "fish")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.75)

            Label {
                Text(session.endReason.title)
            } icon: {
                AssetIcon(name: session.netResult >= 0 ? "icon_scatter_boat" : "icon_warning_badge", size: 20, fallbackSystemImage: session.netResult >= 0 ? "checkmark.circle" : "exclamationmark.triangle")
            }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(session.netResult >= 0 ? Color.appSuccess : Color.orange)
        }
        .padding()
        .panelBackground()
        .accessibilityElement(children: .combine)
    }

    private var durationText: String {
        let minutes = max(1, session.durationSeconds / 60)
        return "\(minutes) min at sea"
    }
}
