import Foundation
import SwiftUI
import Combine

enum AppTab: Hashable {
    case setup
    case live
    case history
    case analytics
    case rules
}

@MainActor
final class AppViewModel: ObservableObject {
    @Published var selectedTab: AppTab = .setup
    @Published var sessions: [FishingSession] = []
    @Published var activeSession: ActiveFishingSession?
    @Published var setup = SessionSetup.empty
    @Published var alertMessage: String?
    @Published var isLoading = false

    private let store = SessionStore()

    var hasHistory: Bool {
        !sessions.isEmpty
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            sessions = try await store.loadSessions()
            activeSession = try await store.loadActiveSession()
            if activeSession != nil {
                selectedTab = .live
            }
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func applyShortPreset() {
        setup.stopLoss = 50
        setup.takeProfit = 100
        setup.durationMinutes = 20
        setup.stake = 1
        if setup.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            setup.location = "Short Trip"
        }
    }

    func applyFullPreset() {
        setup.stopLoss = 150
        setup.takeProfit = 300
        setup.durationMinutes = 40
        setup.stake = 3
        if setup.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            setup.location = "Full Expedition"
        }
    }

    func validationMessage() -> String? {
        let location = setup.location.trimmingCharacters(in: .whitespacesAndNewlines)
        if location.isEmpty {
            return "Enter a location so this expedition is easy to recognize later."
        }
        if setup.stopLoss <= 0 {
            return "Bait reserve must be greater than zero."
        }
        if setup.takeProfit <= 0 {
            return "Boat capacity must be greater than zero."
        }
        if setup.stake <= 0 {
            return "Stake per empty cast must be greater than zero."
        }
        if setup.durationMinutes < 1 || setup.durationMinutes > 120 {
            return "Weather timer must stay between 1 and 120 minutes."
        }
        return nil
    }

    func startSession() {
        if let message = validationMessage() {
            alertMessage = message
            return
        }

        var normalized = setup
        normalized.location = normalized.location.trimmingCharacters(in: .whitespacesAndNewlines)
        activeSession = ActiveFishingSession(setup: normalized)
        selectedTab = .live
        persistActiveSession()
    }

    func record(_ type: CatchEventType, amount: Decimal? = nil) {
        guard var session = activeSession else { return }
        let resolvedAmount: Decimal
        if let amount {
            resolvedAmount = amount
        } else if type == .emptyCast {
            resolvedAmount = -session.setup.stake
        } else {
            resolvedAmount = type.defaultAmount
        }

        session.events.insert(CatchRecord(type: type, amount: resolvedAmount), at: 0)
        activeSession = session
        persistActiveSession()
    }

    func finishActiveSession(reason: SessionEndReason? = nil) {
        guard let session = activeSession else { return }
        let resolvedReason = reason ?? session.limitReason() ?? .manual
        let completed = FishingSession(active: session, endReason: resolvedReason)
        sessions.insert(completed, at: 0)
        activeSession = nil
        selectedTab = resolvedReason == .stopLoss || resolvedReason == .takeProfit ? .analytics : .history

        Task {
            do {
                try await store.saveSessions(sessions)
                try await store.saveActiveSession(nil)
            } catch {
                alertMessage = error.localizedDescription
            }
        }
    }

    func deleteSessions(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
        persistSessions()
    }

    func clearHistory() {
        sessions.removeAll()
        persistSessions()
    }

    private func persistSessions() {
        Task {
            do {
                try await store.saveSessions(sessions)
            } catch {
                alertMessage = error.localizedDescription
            }
        }
    }

    private func persistActiveSession() {
        let session = activeSession
        Task {
            do {
                try await store.saveActiveSession(session)
            } catch {
                alertMessage = error.localizedDescription
            }
        }
    }
}
