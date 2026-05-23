import SwiftUI

struct AnalyticsView: View {
    let sessions: [FishingSession]

    var body: some View {
        let summary = AnalyticsViewModel.summary(for: sessions)

        ZStack {
            OceanBackground(assetName: "water_texture_overlay")

            if sessions.isEmpty {
                EmptyStateView(title: "Sonar Needs Data", message: "After your first completed expedition, ROI, bonuses, and bankroll trends will appear here.", systemImage: "chart.xyaxis.line")
            } else {
                ScrollView {
                    VStack(spacing: 18) {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                            MetricTile(title: "Total Expeditions", value: "\(summary.totalSessions)", assetName: "icon_scatter_boat", fallbackSystemImage: "sailboat")
                            MetricTile(title: "Total ROI", value: String(format: "%+.0f%%", summary.roi), assetName: "icon_balance", fallbackSystemImage: "percent", tint: summary.roi >= 0 ? Color.appSuccess : Color.red)
                            MetricTile(title: "Bonus Pace", value: bonusText(summary), assetName: "icon_timer", fallbackSystemImage: "timer", tint: .orange)
                            MetricTile(title: "Limit Finishes", value: "\(Int(summary.limitSuccessRate * 100))%", assetName: "icon_analytics_sonar", fallbackSystemImage: "target", tint: .blue)
                        }

                        bankrollChart(summary.dailyResults)
                        catchPie(summary: summary)
                    }
                    .padding()
                    .frame(maxWidth: 820)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Sonar")
    }

    private func bonusText(_ summary: AnalyticsSummary) -> String {
        if let minutes = summary.averageBonusMinutes {
            return "\(Int(minutes.rounded())) min"
        }
        return "none"
    }

    private func bankrollChart(_ points: [(date: Date, result: Decimal)]) -> some View {
        let dailyValues = lastSevenDailyValues(from: points)
        let values = dailyValues.map(\.result)
        let maxAbs = max(values.map { abs($0) }.max() ?? 1, 1)
        let ticks = [maxAbs, maxAbs / 2, 0, -maxAbs / 2, -maxAbs]

        return VStack(alignment: .leading, spacing: 12) {
            Text("Bankroll Trend")
                .font(.headline)

            HStack(alignment: .top, spacing: 8) {
                VStack {
                    ForEach(ticks.indices, id: \.self) { index in
                        let tick = ticks[index]
                        Text(axisLabel(tick))
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(tick == 0 ? .primary : .secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        if index != ticks.indices.last {
                            Spacer(minLength: 0)
                        }
                    }
                }
                .frame(width: 54, height: 180)

                VStack(spacing: 6) {
                    GeometryReader { proxy in
                        Canvas { canvas, size in
                            for tick in ticks {
                                let y = pointY(for: tick, maxAbs: maxAbs, height: size.height)
                                var grid = Path()
                                grid.move(to: CGPoint(x: 0, y: y))
                                grid.addLine(to: CGPoint(x: size.width, y: y))
                                canvas.stroke(grid, with: .color(.secondary.opacity(tick == 0 ? 0.42 : 0.18)), lineWidth: tick == 0 ? 1.2 : 1)
                            }

                            var path = Path()
                            for index in dailyValues.indices {
                                let x = size.width * CGFloat(index) / CGFloat(max(dailyValues.count - 1, 1))
                                let y = pointY(for: dailyValues[index].result, maxAbs: maxAbs, height: size.height)
                                if index == dailyValues.startIndex {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                            canvas.stroke(path, with: .color((values.last ?? 0) >= 0 ? Color.appSuccess : Color.red), lineWidth: 3)

                            for index in dailyValues.indices {
                                let x = size.width * CGFloat(index) / CGFloat(max(dailyValues.count - 1, 1))
                                let y = pointY(for: dailyValues[index].result, maxAbs: maxAbs, height: size.height)
                                let rect = CGRect(x: x - 4, y: y - 4, width: 8, height: 8)
                                canvas.fill(Path(ellipseIn: rect), with: .color(dailyValues[index].result >= 0 ? Color.appSuccess : Color.red))
                            }
                        }
                        .frame(width: proxy.size.width, height: proxy.size.height)
                    }
                    .frame(height: 180)

                    HStack {
                        ForEach(dailyValues, id: \.date) { point in
                            Text(dateLabel(point.date))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
        .padding()
        .panelBackground()
    }

    private func catchPie(summary: AnalyticsSummary) -> some View {
        let fisherman = max(0, (summary.fishermanProfit as NSDecimalNumber).doubleValue)
        let total = Double(summary.emptyCastCount + summary.baseCatchCount) + fisherman
        let emptyPart = total == 0 ? 0 : Double(summary.emptyCastCount) / total
        let basePart = total == 0 ? 0 : Double(summary.baseCatchCount) / total

        return VStack(alignment: .leading, spacing: 12) {
            Text("Catch Types")
                .font(.headline)
            HStack(spacing: 18) {
                ZStack {
                    Circle()
                        .trim(from: 0, to: emptyPart)
                        .stroke(.red, lineWidth: 24)
                        .rotationEffect(.degrees(-90))
                    Circle()
                        .trim(from: emptyPart, to: emptyPart + basePart)
                        .stroke(Color.appSuccess, lineWidth: 24)
                        .rotationEffect(.degrees(-90))
                    Circle()
                        .trim(from: emptyPart + basePart, to: 1)
                        .stroke(.orange, lineWidth: 24)
                        .rotationEffect(.degrees(-90))
                    Text(total == 0 ? "0" : "\(Int(total))")
                        .font(.headline.monospacedDigit())
                }
                .frame(width: 120, height: 120)

                VStack(alignment: .leading, spacing: 8) {
                    LegendRow(color: .red, title: "Empty casts", value: "\(summary.emptyCastCount)")
                    LegendRow(color: Color.appSuccess, title: "Base wins", value: "\(summary.baseCatchCount)")
                    LegendRow(color: .orange, title: "Fisherman", value: summary.fishermanProfit.currencyString)
                }
                Spacer()
            }
        }
        .padding()
        .panelBackground()
    }

    private func lastSevenDailyValues(from points: [(date: Date, result: Decimal)]) -> [(date: Date, result: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let grouped = points.reduce(into: [Date: Double]()) { result, point in
            let day = calendar.startOfDay(for: point.date)
            result[day, default: 0] += (point.result as NSDecimalNumber).doubleValue
        }

        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: start) ?? start
            return (date, grouped[date] ?? 0)
        }
    }

    private func pointY(for value: Double, maxAbs: Double, height: CGFloat) -> CGFloat {
        let normalized = (value + maxAbs) / (maxAbs * 2)
        return height * CGFloat(1 - normalized)
    }

    private func axisLabel(_ value: Double) -> String {
        if abs(value) >= 1000 {
            return String(format: "%+.1fk", value / 1000)
        }
        return String(format: "%+.0f", value)
    }

    private func dateLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd"
        return formatter.string(from: date)
    }
}

private struct LegendRow: View {
    let color: Color
    let title: String
    let value: String

    var body: some View {
        HStack {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(title)
            Spacer()
            Text(value).font(.subheadline.monospacedDigit())
        }
        .font(.subheadline)
    }
}
