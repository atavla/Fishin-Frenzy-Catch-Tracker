import SwiftUI
import Combine

struct LiveTrackerView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var now = Date()
    @State private var eventForAmount: CatchEventType?
    @State private var amountText = ""
    @State private var showFinishConfirmation = false

    var body: some View {
        ZStack {
            OceanBackground(assetName: "live_tracker_ocean_background")

            if let session = viewModel.activeSession {
                activeContent(session: session)
            } else {
                EmptyStateView(title: "Still at the Dock", message: "Set your bait reserve, target, and timer to start a disciplined expedition.", systemImage: "anchor", actionTitle: "Set Up Gear") {
                    viewModel.selectedTab = .setup
                }
            }

            if viewModel.activeSession != nil {
                VStack {
                    HStack {
                        Spacer()
                        portButton
                            .padding(.trailing, 16)
                    }
                    .padding(.top, 8)
                    Spacer()
                }
            }
        }
        .navigationTitle("At Sea")
        .confirmationDialog("Finish this expedition?", isPresented: $showFinishConfirmation, titleVisibility: .visible) {
            Button("Save and Return to Port") {
                viewModel.finishActiveSession(reason: .manual)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The current result will be saved to the Keepnet.")
        }
        .sheet(item: $eventForAmount) { event in
            AmountEntryView(event: event, amountText: $amountText) { amount in
                let signedAmount = event == .emptyCast ? -amount : amount
                viewModel.record(event, amount: signedAmount)
                eventForAmount = nil
            }
            .presentationDetents([.height(280)])
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
            now = date
        }
    }

    private var portButton: some View {
        Button {
            showFinishConfirmation = true
        } label: {
            Image("icon_port_home")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: 76, height: 76)
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .accessibilityLabel("Return to port")
    }

    private func activeContent(session: ActiveFishingSession) -> some View {
        let reason = session.limitReason(now: now)

        return ScrollView {
            VStack(spacing: 18) {
                statusPanel(session: session)
                catchButtons(session: session, isLocked: reason != nil)
                recentEvents(session: session)
            }
            .padding()
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
    }

    private func statusPanel(session: ActiveFishingSession) -> some View {
        let seconds = session.secondsRemaining(now: now)
        let timeTint: Color = seconds < 180 ? Color.red : (seconds < 600 ? Color.orange : Color.appSuccess)

        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                MetricTile(title: "Timer", value: seconds.clockString, assetName: "icon_timer", fallbackSystemImage: "timer", tint: timeTint)
                MetricTile(title: "Balance", value: session.currentBalance.currencyString, assetName: "icon_balance", fallbackSystemImage: "dollarsign.circle", tint: session.netResult >= 0 ? Color.appSuccess : Color.red)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label {
                        Text("Bait Reserve")
                    } icon: {
                        AssetIcon(name: "icon_warning_badge", size: 22, fallbackSystemImage: "shippingbox")
                    }
                    Spacer()
                    Text("\(Int(session.baitProgress * 100))%")
                        .font(.headline.monospacedDigit())
                }
                ProgressView(value: session.baitProgress)
                    .tint(session.baitProgress < 0.2 ? .red : .blue)
                Text("\(session.setup.location) · target \(session.setup.takeProfit.currencyString) · stake \(session.setup.stake.currencyString)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .panelBackground()
        }
    }

    private func catchButtons(session: ActiveFishingSession, isLocked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Catch Panel")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 148), spacing: 12)], spacing: 12) {
                CatchButton(type: .emptyCast, subtitle: "-\(session.setup.stake.currencyString)", disabled: isLocked, action: {
                    viewModel.record(.emptyCast)
                }, settingsAction: {
                    beginAmountEntry(.emptyCast)
                })
                CatchButton(type: .smallCatch, subtitle: "+\(CatchEventType.smallCatch.defaultAmount.currencyString)", disabled: isLocked, action: {
                    viewModel.record(.smallCatch)
                }, settingsAction: {
                    beginAmountEntry(.smallCatch)
                })
                CatchButton(type: .pelican, subtitle: "+\(CatchEventType.pelican.defaultAmount.currencyString)", disabled: isLocked, action: {
                    viewModel.record(.pelican)
                }, settingsAction: {
                    beginAmountEntry(.pelican)
                })
                CatchButton(type: .scatterBoat, subtitle: "+\(CatchEventType.scatterBoat.defaultAmount.currencyString)", disabled: isLocked, action: {
                    viewModel.record(.scatterBoat, amount: 0)
                }, settingsAction: {
                    beginAmountEntry(.scatterBoat)
                })
                CatchButton(type: .fisherman, subtitle: "+\(CatchEventType.fisherman.defaultAmount.currencyString)", disabled: isLocked, action: {
                    viewModel.record(.fisherman)
                }, settingsAction: {
                    beginAmountEntry(.fisherman)
                })
            }
        }
        .padding()
        .panelBackground()
    }

    private func recentEvents(session: ActiveFishingSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Events")
                .font(.headline)
            if session.events.isEmpty {
                Text("Your first result will appear here after you tap the catch panel.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .panelBackground(cornerRadius: 12)
            } else {
                ForEach(session.events.prefix(6)) { event in
                    HStack {
                        AssetIcon(name: event.type.assetName, size: 34, fallbackSystemImage: event.type.systemImage)
                        VStack(alignment: .leading) {
                            Text(event.type.title)
                            Text(event.date, style: .time)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(event.amount.currencyString)
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(event.amount >= 0 ? Color.appSuccess : Color.red)
                    }
                    .padding(10)
                    .panelBackground(cornerRadius: 12)
                }
            }
        }
    }

    private func beginAmountEntry(_ event: CatchEventType) {
        amountText = NSDecimalNumber(decimal: event.defaultAmount).stringValue
        eventForAmount = event
    }
}

private struct CatchButton: View {
    let type: CatchEventType
    let subtitle: String
    let disabled: Bool
    let action: () -> Void
    let settingsAction: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: action) {
                VStack(spacing: 10) {
                    AssetGraphic(name: type.assetName, mode: .contain, fallbackSystemImage: type.systemImage)
                        .frame(height: 58)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Text(type.shortTitle)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .frame(maxWidth: .infinity, minHeight: 132)
            }
            .buttonStyle(.bordered)
            .disabled(disabled)

            Button(action: settingsAction) {
                Image(systemName: "slider.horizontal.3")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.blue)
                    .frame(width: 30, height: 30)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(disabled)
            .padding(6)
            .accessibilityLabel("Customize \(type.title) amount")
        }
        .accessibilityHint(disabled ? "The session has reached a stop signal" : "Adds an event to the current session")
    }
}

private struct AmountEntryView: View {
    let event: CatchEventType
    @Binding var amountText: String
    let onSave: (Decimal) -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Win amount", text: $amountText)
                        .keyboardType(.decimalPad)
                        .focused($isFocused)
                    if let error {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text(event.title)
                } footer: {
                    Text("Enter the actual amount shown by the slot.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(red: 0.73, green: 0.91, blue: 1.0).opacity(0.45))
            .navigationTitle("Log Catch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let normalized = amountText.replacingOccurrences(of: ",", with: ".")
                        guard let amount = Decimal(string: normalized), amount >= 0 else {
                            error = "Enter an amount of 0 or more."
                            return
                        }
                        onSave(amount)
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isFocused = false }
                }
            }
            .onAppear { isFocused = true }
        }
    }
}

struct StopSignalScreen: View {
    let reason: SessionEndReason
    let action: () -> Void

    var body: some View {
        ZStack {
            AssetGraphic(name: reason == .takeProfit ? "take_profit_background" : "stop_loss_background", mode: .cover)
                .ignoresSafeArea()
            Color(reason == .takeProfit ? .orange : .red)
                .opacity(0.20)
                .ignoresSafeArea()

            VStack {
                Spacer()
                Button(action: action) {
                    Text("Return to Port")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(buttonColor, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Return to Port")
                .padding(.horizontal, 28)
                .padding(.bottom, 34)
            }
        }
    }

    private var buttonColor: Color {
        reason == .stopLoss ? .yellow : .red
    }
}
