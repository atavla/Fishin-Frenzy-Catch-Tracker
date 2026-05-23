import Foundation

struct AnalyticsSummary {
    let totalSessions: Int
    let totalNet: Decimal
    let roi: Double
    let averageBonusMinutes: Double?
    let limitSuccessRate: Double
    let emptyCastCount: Int
    let baseCatchCount: Int
    let fishermanProfit: Decimal
    let dailyResults: [(date: Date, result: Decimal)]
}

enum AnalyticsViewModel {
    static func summary(for sessions: [FishingSession]) -> AnalyticsSummary {
        let totalStopLoss = sessions.reduce(Decimal.zero) { $0 + $1.setup.stopLoss }
        let totalNet = sessions.reduce(Decimal.zero) { $0 + $1.netResult }
        let roi = totalStopLoss > 0 ? ((totalNet as NSDecimalNumber).doubleValue / (totalStopLoss as NSDecimalNumber).doubleValue) * 100 : 0

        let sessionsWithBonus = sessions.filter { $0.bonusCount > 0 }
        let averageBonusMinutes: Double?
        if sessionsWithBonus.isEmpty {
            averageBonusMinutes = nil
        } else {
            let seconds = sessionsWithBonus.reduce(0) { $0 + $1.durationSeconds }
            let bonuses = sessionsWithBonus.reduce(0) { $0 + $1.bonusCount }
            averageBonusMinutes = bonuses > 0 ? Double(seconds) / 60 / Double(bonuses) : nil
        }

        let limitFinished = sessions.filter { $0.endReason == .takeProfit || $0.endReason == .stopLoss }.count
        let successRate = sessions.isEmpty ? 0 : Double(limitFinished) / Double(sessions.count)

        let allEvents = sessions.flatMap(\.events)
        let emptyCount = allEvents.filter { $0.type == .emptyCast }.count
        let baseCount = allEvents.filter { $0.type == .smallCatch || $0.type == .pelican }.count
        let fishermanProfit = allEvents.filter { $0.type == .fisherman }.reduce(Decimal.zero) { $0 + $1.amount }

        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sessions) { calendar.startOfDay(for: $0.startedAt) }
        let dailyResults = grouped.map { key, value in
            (date: key, result: value.reduce(Decimal.zero) { $0 + $1.netResult })
        }
        .sorted { $0.date < $1.date }

        return AnalyticsSummary(totalSessions: sessions.count, totalNet: totalNet, roi: roi, averageBonusMinutes: averageBonusMinutes, limitSuccessRate: successRate, emptyCastCount: emptyCount, baseCatchCount: baseCount, fishermanProfit: fishermanProfit, dailyResults: dailyResults)
    }
}
