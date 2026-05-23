import SwiftUI
import UIKit

extension Color {
    static let appSuccess = Color(red: 0.0, green: 0.42, blue: 0.22)
}

enum AppImageMode {
    case cover
    case contain
    case fill
}

struct AssetGraphic: View {
    let name: String
    let mode: AppImageMode
    var fallbackSystemImage: String?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Image(name)
                    .resizable()
                    .renderingMode(.original)
                    .modifier(ImageModeModifier(mode: mode, size: proxy.size))
                if let fallbackSystemImage {
                    Image(systemName: fallbackSystemImage)
                        .font(.system(size: min(proxy.size.width, proxy.size.height) * 0.38, weight: .semibold))
                        .foregroundStyle(.blue.opacity(0.55))
                        .accessibilityHidden(true)
                }
            }
        }
    }
}

struct AssetIcon: View {
    let name: String
    var size: CGFloat = 24
    var fallbackSystemImage: String?

    var body: some View {
        AssetGraphic(name: name, mode: .contain, fallbackSystemImage: fallbackSystemImage)
            .frame(width: size, height: size)
            .clipped()
            .accessibilityHidden(true)
    }
}

struct TabAssetIcon: View {
    let name: String

    var body: some View {
        Image(uiImage: UIImage.resizedAsset(named: name, pointSize: CGSize(width: 22, height: 22)))
            .renderingMode(.original)
    }
}

extension UIImage {
    static func resizedAsset(named name: String, pointSize: CGSize) -> UIImage {
        guard let image = UIImage(named: name) else {
            return UIImage()
        }

        let renderer = UIGraphicsImageRenderer(size: pointSize)
        return renderer.image { _ in
            let originalSize = image.size
            guard originalSize.width > 0, originalSize.height > 0 else { return }

            let scale = min(pointSize.width / originalSize.width, pointSize.height / originalSize.height)
            let drawSize = CGSize(width: originalSize.width * scale, height: originalSize.height * scale)
            let origin = CGPoint(x: (pointSize.width - drawSize.width) / 2, y: (pointSize.height - drawSize.height) / 2)
            image.draw(in: CGRect(origin: origin, size: drawSize))
        }.withRenderingMode(.alwaysOriginal)
    }
}

private struct ImageModeModifier: ViewModifier {
    let mode: AppImageMode
    let size: CGSize

    func body(content: Content) -> some View {
        switch mode {
        case .cover:
            content.scaledToFill().frame(width: size.width, height: size.height)
        case .contain:
            content.scaledToFit().frame(width: size.width, height: size.height)
        case .fill:
            content.frame(width: size.width, height: size.height)
        }
    }
}

struct OceanBackground: View {
    let assetName: String

    var body: some View {
        ZStack {
            AssetGraphic(name: assetName, mode: .cover)
            LinearGradient(colors: [.cyan.opacity(0.25), .blue.opacity(0.14), .white.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
            WaveOverlay()
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct WaveOverlay: View {
    var body: some View {
        TimelineView(.animation) { context in
            Canvas { canvas, size in
                let t = context.date.timeIntervalSinceReferenceDate
                for index in 0..<6 {
                    var path = Path()
                    let y = size.height * (0.25 + Double(index) * 0.11)
                    path.move(to: CGPoint(x: 0, y: y))
                    for x in stride(from: 0, through: size.width, by: 12) {
                        let phase = Double(x) / 42 + t * 0.45 + Double(index)
                        path.addLine(to: CGPoint(x: x, y: y + sin(phase) * 8))
                    }
                    canvas.stroke(path, with: .color(.white.opacity(0.20)), lineWidth: 2)
                }
            }
        }
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    let assetName: String
    var fallbackSystemImage: String = "circle"
    var tint: Color = .blue

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            AssetIcon(name: assetName, size: 34, fallbackSystemImage: fallbackSystemImage)
            Text(value)
                .font(.title2.monospacedDigit().bold())
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.75)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .panelBackground(cornerRadius: 14)
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.blue)
            Text(title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(28)
        .frame(maxWidth: 460)
        .panelBackground(cornerRadius: 18)
    }
}

struct PanelBackground: ViewModifier {
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(red: 0.73, green: 0.91, blue: 1.0).opacity(0.42))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            }
    }
}

extension View {
    func panelBackground(cornerRadius: CGFloat = 16) -> some View {
        modifier(PanelBackground(cornerRadius: cornerRadius))
    }
}

extension Decimal {
    var currencyString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: self as NSDecimalNumber) ?? "$0"
    }
}

extension Int {
    var clockString: String {
        let minutes = self / 60
        let seconds = self % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

extension Binding where Value == Decimal {
    func decimalText() -> Binding<String> {
        Binding<String>(
            get: {
                NSDecimalNumber(decimal: wrappedValue).stringValue
            },
            set: { newValue in
                let normalized = newValue.replacingOccurrences(of: ",", with: ".")
                if let value = Decimal(string: normalized) {
                    wrappedValue = value
                } else if newValue.isEmpty {
                    wrappedValue = 0
                }
            }
        )
    }
}
