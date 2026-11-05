import Photos
import SwiftUI

/// Une carte photo. Le déplacement (`offset`) est piloté par le parent,
/// ce qui permet de déclencher le même mouvement au doigt ou avec les boutons.
struct SwipeCardView: View {
    let asset: PHAsset
    var offset: CGSize = .zero
    /// Distance à partir de laquelle le swipe est validé.
    var threshold: CGFloat = 120

    private var progress: CGFloat { min(abs(offset.width) / threshold, 1) }

    var body: some View {
        AssetImageView(asset: asset, contentMode: .fill)
            .overlay(alignment: .top) {
                infoPill.opacity(1 - progress)
            }
            .overlay(alignment: .topLeading) {
                stamp("GARDER", color: .green, angle: -15)
                    .opacity(offset.width > 0 ? progress : 0)
            }
            .overlay(alignment: .topTrailing) {
                stamp("SUPPRIMER", color: .red, angle: 15)
                    .opacity(offset.width < 0 ? progress : 0)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
            .offset(offset)
            .rotationEffect(.degrees(Double(offset.width) / 20), anchor: .bottom)
    }

    /// Pastille en verre posée sur la photo : date et type.
    private var infoPill: some View {
        HStack(spacing: 8) {
            if asset.mediaSubtypes.contains(.photoScreenshot) {
                Image(systemName: MediaCategory.screenshot.systemImage)
            }
            if let date = asset.creationDate {
                Text(date, format: .dateTime.day().month(.wide).year())
            }
        }
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: .capsule)
        .padding(.top, 16)
    }

    private func stamp(_ text: String, color: Color, angle: Double) -> some View {
        Text(text)
            .font(.title.weight(.heavy))
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(color, lineWidth: 4))
            .rotationEffect(.degrees(angle))
            .padding(24)
    }
}
