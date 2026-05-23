import Foundation

enum SessionEndReason: String, Codable, CaseIterable, Identifiable {
    case takeProfit
    case stopLoss
    case timeExpired
    case manual

    var id: String { rawValue }

    var title: String {
        switch self {
        case .takeProfit: "Boat Full"
        case .stopLoss: "Out of Bait"
        case .timeExpired: "Weather Timer Ended"
        case .manual: "Returned to Port"
        }
    }
}

enum CatchEventType: String, Codable, CaseIterable, Identifiable {
    case emptyCast
    case smallCatch
    case pelican
    case scatterBoat
    case fisherman

    var id: String { rawValue }

    var title: String {
        switch self {
        case .emptyCast: "Empty Cast"
        case .smallCatch: "Small School"
        case .pelican: "Pelican"
        case .scatterBoat: "Scatter Boat"
        case .fisherman: "Fisherman"
        }
    }

    var shortTitle: String {
        switch self {
        case .emptyCast: "Empty"
        case .smallCatch: "Fish"
        case .pelican: "Pelican"
        case .scatterBoat: "Scatter"
        case .fisherman: "Fisher"
        }
    }

    var systemImage: String {
        switch self {
        case .emptyCast: "water.waves"
        case .smallCatch: "fish"
        case .pelican: "bird"
        case .scatterBoat: "sailboat"
        case .fisherman: "figure.fishing"
        }
    }

    var assetName: String {
        switch self {
        case .emptyCast: "icon_empty_cast"
        case .smallCatch: "icon_small_fish"
        case .pelican: "icon_pelican"
        case .scatterBoat: "icon_scatter_boat"
        case .fisherman: "icon_fisherman_wild"
        }
    }

    var defaultAmount: Decimal {
        switch self {
        case .emptyCast: -1
        case .smallCatch: 5
        case .pelican: 25
        case .scatterBoat: 0
        case .fisherman: 50
        }
    }
}

struct SessionSetup: Codable, Equatable {
    var location: String
    var stopLoss: Decimal
    var takeProfit: Decimal
    var durationMinutes: Int
    var stake: Decimal

    static let empty = SessionSetup(location: "", stopLoss: 100, takeProfit: 200, durationMinutes: 30, stake: 1)
}

struct CatchRecord: Identifiable, Codable, Equatable {
    var id: UUID
    var type: CatchEventType
    var amount: Decimal
    var date: Date

    init(id: UUID = UUID(), type: CatchEventType, amount: Decimal, date: Date = Date()) {
        self.id = id
        self.type = type
        self.amount = amount
        self.date = date
    }
}

struct ActiveFishingSession: Identifiable, Codable, Equatable {
    var id: UUID
    var setup: SessionSetup
    var startedAt: Date
    var events: [CatchRecord]

    init(id: UUID = UUID(), setup: SessionSetup, startedAt: Date = Date(), events: [CatchRecord] = []) {
        self.id = id
        self.setup = setup
        self.startedAt = startedAt
        self.events = events
    }

    var plannedEndAt: Date {
        startedAt.addingTimeInterval(TimeInterval(setup.durationMinutes * 60))
    }

    var netResult: Decimal {
        events.reduce(Decimal.zero) { $0 + $1.amount }
    }

    var currentBalance: Decimal {
        setup.stopLoss + netResult
    }

    var baitProgress: Double {
        guard setup.stopLoss > 0 else { return 0 }
        let value = (currentBalance as NSDecimalNumber).doubleValue / (setup.stopLoss as NSDecimalNumber).doubleValue
        return min(max(value, 0), 1)
    }

    func secondsRemaining(now: Date = Date()) -> Int {
        max(0, Int(plannedEndAt.timeIntervalSince(now)))
    }

    func elapsedSeconds(now: Date = Date()) -> Int {
        max(0, Int(now.timeIntervalSince(startedAt)))
    }

    func limitReason(now: Date = Date()) -> SessionEndReason? {
        if netResult >= setup.takeProfit {
            return .takeProfit
        }
        if currentBalance <= 0 {
            return .stopLoss
        }
        if secondsRemaining(now: now) == 0 {
            return .timeExpired
        }
        return nil
    }

    var bonusCount: Int {
        events.filter { $0.type == .scatterBoat || $0.type == .fisherman }.count
    }

    var maxCatch: Decimal {
        events.map(\.amount).max() ?? 0
    }
}

struct FishingSession: Identifiable, Codable, Equatable {
    var id: UUID
    var setup: SessionSetup
    var startedAt: Date
    var endedAt: Date
    var events: [CatchRecord]
    var endReason: SessionEndReason

    init(active: ActiveFishingSession, endedAt: Date = Date(), endReason: SessionEndReason) {
        id = active.id
        setup = active.setup
        startedAt = active.startedAt
        self.endedAt = endedAt
        events = active.events
        self.endReason = endReason
    }

    var netResult: Decimal {
        events.reduce(Decimal.zero) { $0 + $1.amount }
    }

    var durationSeconds: Int {
        max(0, Int(endedAt.timeIntervalSince(startedAt)))
    }

    var bonusCount: Int {
        events.filter { $0.type == .scatterBoat || $0.type == .fisherman }.count
    }

    var maxCatch: Decimal {
        events.map(\.amount).max() ?? 0
    }
}

struct RuleCard: Identifiable {
    let id = UUID()
    let title: String
    let text: String
    let symbolName: String
    let assetName: String

    static let defaults = [
        RuleCard(title: "Do Not Chase the Golden Fish", text: "The slot RTP is 96.12%. The ocean keeps about 4%. Your job is to catch a lucky wave and leave on time, not to beat the math.", symbolName: "fish", assetName: "illustration_rule_golden_fish"),
        RuleCard(title: "Empty Bait Box", text: "If your bait limit is gone, reel in. Chasing losses drags the trip down.", symbolName: "tray", assetName: "illustration_rule_empty_bait_box"),
        RuleCard(title: "Boat Full", text: "Reached your take-profit capacity? Close the game. Greed sinks boats.", symbolName: "sailboat", assetName: "illustration_rule_full_boat"),
        RuleCard(title: "Change Waters", text: "If there is no scatter after 20 minutes, take a break. No bite means it is time to rest the gear.", symbolName: "arrow.triangle.2.circlepath", assetName: "illustration_rule_change_water"),
        RuleCard(title: "Compass Rule", text: "After 3 losses in a row, stop for 1 minute. Adrenaline bends your course.", symbolName: "safari", assetName: "illustration_rule_compass")
    ]
}
