import Photos
import UIKit

/// Toute la communication avec PhotoKit passe par ici.
final class PhotoLibraryService {
    static let shared = PhotoLibraryService()

    private let imageManager = PHCachingImageManager()

    // MARK: - Autorisation

    var authorizationStatus: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestAuthorization() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    // MARK: - Récupération

    /// Les images correspondant aux catégories, triées de la plus ancienne à la plus récente.
    func fetchImages(categories: Set<MediaCategory>) -> [PHAsset] {
        guard !categories.isEmpty else { return [] }

        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        let screenshotBit = PHAssetMediaSubtype.photoScreenshot.rawValue
        let imageType = PHAssetMediaType.image.rawValue

        switch (categories.contains(.photo), categories.contains(.screenshot)) {
        case (true, true):
            options.predicate = NSPredicate(format: "mediaType == %d", imageType)
        case (true, false):
            options.predicate = NSPredicate(
                format: "mediaType == %d AND (mediaSubtypes & %d) == 0", imageType, screenshotBit)
        case (false, true):
            options.predicate = NSPredicate(
                format: "mediaType == %d AND (mediaSubtypes & %d) != 0", imageType, screenshotBit)
        case (false, false):
            return []
        }

        let result = PHAsset.fetchAssets(with: options)
        var assets: [PHAsset] = []
        assets.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in assets.append(asset) }
        return assets
    }

    func fetchAssets(identifiers: [String]) -> [PHAsset] {
        guard !identifiers.isEmpty else { return [] }
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let result = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: options)
        var assets: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in assets.append(asset) }
        return assets
    }

    // MARK: - Images

    /// Flux d'images : une version basse qualité arrive vite, puis la version finale.
    /// Les photos stockées uniquement sur iCloud sont téléchargées si besoin.
    func images(for asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode = .aspectFill) -> AsyncStream<UIImage> {
        AsyncStream { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.isNetworkAccessAllowed = true
            options.resizeMode = .fast

            let requestID = imageManager.requestImage(
                for: asset, targetSize: targetSize, contentMode: contentMode, options: options
            ) { image, info in
                if let image { continuation.yield(image) }
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                let cancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
                let failed = info?[PHImageErrorKey] != nil
                if !isDegraded || cancelled || failed {
                    continuation.finish()
                }
            }

            continuation.onTermination = { [imageManager] _ in
                imageManager.cancelImageRequest(requestID)
            }
        }
    }

    /// Prépare en avance les images des prochaines cartes pour un swipe fluide.
    func startCaching(_ assets: [PHAsset], targetSize: CGSize) {
        imageManager.startCachingImages(for: assets, targetSize: targetSize, contentMode: .aspectFill, options: nil)
    }

    func stopCachingAll() {
        imageManager.stopCachingImagesForAllAssets()
    }

    // MARK: - Suppression

    /// Supprime les photos. iOS affiche une seule alerte de confirmation pour tout le lot.
    /// Lève une erreur si l'utilisateur refuse.
    func delete(_ assets: [PHAsset]) async throws {
        guard !assets.isEmpty else { return }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        }
    }
}
