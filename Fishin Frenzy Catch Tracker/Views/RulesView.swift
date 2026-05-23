import SwiftUI

struct RulesView: View {
    var body: some View {
        ZStack {
            OceanBackground(assetName: "water_texture_overlay")
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("A responsible gaming guide wrapped in nautical metaphors.")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    ForEach(RuleCard.defaults) { rule in
                        RuleCardView(rule: rule)
                    }
                }
                .padding(.vertical)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Fisherman's Rules")
    }
}

private struct RuleCardView: View {
    let rule: RuleCard

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            AssetGraphic(name: rule.assetName, mode: .cover, fallbackSystemImage: rule.symbolName)
                .frame(width: 86, height: 86)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(rule.title)
                    .font(.headline)
                Text(rule.text)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .panelBackground()
        .padding(.horizontal)
    }
}
