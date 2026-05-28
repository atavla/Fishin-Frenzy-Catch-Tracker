import SwiftUI

struct SetupView: View {
    @ObservedObject var viewModel: AppViewModel
    @FocusState private var focusedField: Field?

    private enum Field {
        case location
        case stopLoss
        case takeProfit
        case stake
    }

    var body: some View {
        ZStack {
            OceanBackground(assetName: "session_setup_background")

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    presetSection
                    formSection
                    startButton
                }
                .padding()
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Gear Setup")
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            AssetGraphic(name: "app_logo_hook_wave", mode: .contain, fallbackSystemImage: "water.waves")
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            Text("Fishing Game: Catch Tracker")
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)
            Text("Count your bait. Collect the catch. Return to shore on time.")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .panelBackground(cornerRadius: 18)
    }

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Presets")
                .font(.headline)
            HStack(spacing: 12) {
                Button {
                    viewModel.applyShortPreset()
                } label: {
                    Label {
                        Text("20 min / $50")
                    } icon: {
                        AssetIcon(name: "icon_timer", size: 22, fallbackSystemImage: "clock")
                    }
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    viewModel.applyFullPreset()
                } label: {
                    Label {
                        Text("40 min / $150")
                    } icon: {
                        AssetIcon(name: "icon_scatter_boat", size: 22, fallbackSystemImage: "sailboat")
                    }
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .panelBackground()
    }

    private var formSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            TextField("Location or casino", text: $viewModel.setup.location)
                .textContentType(.organizationName)
                .submitLabel(.next)
                .focused($focusedField, equals: .location)
                .textFieldStyle(.roundedBorder)

            numericField(title: "Bait Reserve (Stop-Loss)", value: $viewModel.setup.stopLoss, field: .stopLoss, assetName: "icon_warning_badge", fallbackIcon: "shippingbox")
            numericField(title: "Boat Capacity (Take-Profit)", value: $viewModel.setup.takeProfit, field: .takeProfit, assetName: "icon_scatter_boat", fallbackIcon: "sailboat")
            numericField(title: "Stake per Empty Cast", value: $viewModel.setup.stake, field: .stake, assetName: "icon_balance", fallbackIcon: "dollarsign.circle")

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label {
                        Text("Weather Timer")
                    } icon: {
                        AssetIcon(name: "icon_timer", size: 22, fallbackSystemImage: "timer")
                    }
                    Spacer()
                    Text("\(viewModel.setup.durationMinutes) min")
                        .font(.headline.monospacedDigit())
                }
                Slider(value: Binding(get: {
                    Double(viewModel.setup.durationMinutes)
                }, set: {
                    viewModel.setup.durationMinutes = Int($0.rounded())
                }), in: 1...120, step: 1)
                Text("Longer play leads to fatigue and rough weather. Set a firm window from 1 to 120 minutes.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .panelBackground()
    }

    private func numericField(title: String, value: Binding<Decimal>, field: Field, assetName: String, fallbackIcon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(title)
            } icon: {
                AssetIcon(name: assetName, size: 22, fallbackSystemImage: fallbackIcon)
            }
                .font(.subheadline.weight(.semibold))
            TextField("0", text: value.decimalText())
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: field)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel(title)
        }
    }

    private var startButton: some View {
        Button {
            focusedField = nil
            viewModel.startSession()
        } label: {
            Label {
                Text("Set Sail")
            } icon: {
                AssetIcon(name: "icon_anchor_start", size: 24, fallbackSystemImage: "anchor")
            }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .tint(.orange)
        .accessibilityHint("Starts the session after checking your limits")
    }
}
