import SwiftUI

struct RootView: View {
    @StateObject private var viewModel = AppViewModel()

    var body: some View {
        ZStack {
            TabView(selection: $viewModel.selectedTab) {
                NavigationStack {
                    SetupView(viewModel: viewModel)
                }
                .tabItem {
                    TabAssetIcon(name: "icon_anchor_start")
                    Text("Setup")
                }
                .tag(AppTab.setup)

                NavigationStack {
                    LiveTrackerView(viewModel: viewModel)
                }
                .tabItem {
                    TabAssetIcon(name: "icon_scatter_boat")
                    Text("At Sea")
                }
                .tag(AppTab.live)

                NavigationStack {
                    HistoryView(viewModel: viewModel)
                }
                .tabItem {
                    TabAssetIcon(name: "icon_archive_calendar")
                    Text("Keepnet")
                }
                .tag(AppTab.history)

                NavigationStack {
                    AnalyticsView(sessions: viewModel.sessions)
                }
                .tabItem {
                    TabAssetIcon(name: "icon_analytics_sonar")
                    Text("Sonar")
                }
                .tag(AppTab.analytics)

                NavigationStack {
                    RulesView()
                }
                .tabItem {
                    TabAssetIcon(name: "icon_rules_codex")
                    Text("Rules")
                }
                .tag(AppTab.rules)
            }

            if let reason = activeStopSignal {
                StopSignalScreen(reason: reason) {
                    viewModel.finishActiveSession(reason: reason)
                }
                .zIndex(10)
            }
        }
        .task {
            await viewModel.load()
        }
        .alert("Heads Up", isPresented: Binding(get: { viewModel.alertMessage != nil }, set: { if !$0 { viewModel.alertMessage = nil } })) {
            Button("OK", role: .cancel) { viewModel.alertMessage = nil }
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
    }

    private var activeStopSignal: SessionEndReason? {
        guard let reason = viewModel.activeSession?.limitReason(),
              reason == .stopLoss || reason == .takeProfit else {
            return nil
        }
        return reason
    }
}

