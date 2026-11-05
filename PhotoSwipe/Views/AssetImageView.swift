import Photos
import SwiftUI

/// Affiche un `PHAsset`, d'abord en basse qualité puis en qualité finale.
struct AssetImageView: View {
    let asset: PHAsset
    var contentMode: ContentMode = .fill

    @Environment(\.displayScale) private var displayScale
    @State private var image: UIImage?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color(.secondarySystemBackground)
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                } else {
                    ProgressView()
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
            .task(id: asset.localIdentifier) {
                image = nil
                let size = CGSize(width: proxy.size.width * displayScale,
                                  height: proxy.size.height * displayScale)
                let mode: PHImageContentMode = contentMode == .fill ? .aspectFill : .aspectFit
                for await loaded in PhotoLibraryService.shared.images(for: asset, targetSize: size, contentMode: mode) {
                    image = loaded
                }
            }
        }
    }
}
