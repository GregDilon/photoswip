import Foundation
import Observation
import Photos
import SwiftData

@MainActor
@Observable
final class SortingViewModel {
    // MARK: - État exposé aux vues

    private(set) var queue: [PHAsset] = []
    private(set) var isLoading = false
    private(set) var trashCount = 0
    private(set) var sortedCount = 0

    var selectedCategories: Set<MediaCategory> = [.photo, .screenshot] {
        didSet { reload() }
    }

    var canUndo: Bool { !history.isEmpty }

    // MARK: - Dépendances

    private let context: ModelContext
    private let library: PhotoLibraryService
    /// Les photos décidées pendant cette session, pour l'undo (la plus récente en dernier).
    private var history: [PHAsset] = []
    private let cacheSize = CGSize(width: 1200, height: 1600)

    init(context: ModelContext, library: PhotoLibraryService = .shared) {
        self.context = context
        self.library = library
    }

    // MARK: - Chargement

    func reload() {
        isLoading = true
        let decided = decidedIDs()
        queue = library.fetchImages(categories: selectedCategories)
            .filter { !decided.contains($0.localIdentifier) }
        history.removeAll()
        refreshCounts()
        preheat()
        isLoading = false
    }

    // MARK: - Décisions

    func decide(_ decision: Decision) {
        guard let asset = queue.first else { return }
        upsert(assetID: asset.localIdentifier, decision: decision)
        queue.removeFirst()
        history.append(asset)
        refreshCounts()
        preheat()
    }

    func undo() {
        guard let asset = history.popLast() else { return }
        if let existing = fetchDecision(assetID: asset.localIdentifier) {
            context.delete(existing)
            save()
        }
        queue.insert(asset, at: 0)
        refreshCounts()
    }

    // MARK: - Corbeille

    func trashedAssets() -> [PHAsset] {
        library.fetchAssets(identifiers: trashDecisions().map(\.assetID))
    }

    /// Retire une photo de la corbeille : elle est considérée comme gardée.
    func restore(_ asset: PHAsset) {
        upsert(assetID: asset.localIdentifier, decision: .keep)
        history.removeAll { $0.localIdentifier == asset.localIdentifier }
        refreshCounts()
    }

    /// Supprime définitivement (vers « Supprimés récemment ») toutes les photos de la corbeille.
    /// Renvoie `false` si l'utilisateur a refusé la confirmation iOS.
    func emptyTrash() async -> Bool {
        let decisions = trashDecisions()
        let assets = library.fetchAssets(identifiers: decisions.map(\.assetID))
        do {
            try await library.delete(assets)
        } catch {
            return false
        }
        decisions.forEach(context.delete)
        save()
        history.removeAll()
        refreshCounts()
        return true
    }

    // MARK: - SwiftData

    private func decidedIDs() -> Set<String> {
        let all = (try? context.fetch(FetchDescriptor<SortDecision>())) ?? []
        return Set(all.map(\.assetID))
    }

    private func trashDecisions() -> [SortDecision] {
        let trash = Decision.trash.rawValue
        let descriptor = FetchDescriptor<SortDecision>(
            predicate: #Predicate { $0.decisionRaw == trash },
            sortBy: [SortDescriptor(\.decidedAt)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    private func fetchDecision(assetID: String) -> SortDecision? {
        var descriptor = FetchDescriptor<SortDecision>(predicate: #Predicate { $0.assetID == assetID })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private func upsert(assetID: String, decision: Decision) {
        if let existing = fetchDecision(assetID: assetID) {
            existing.decision = decision
            existing.decidedAt = .now
        } else {
            context.insert(SortDecision(assetID: assetID, decision: decision))
        }
        save()
    }

    private func refreshCounts() {
        trashCount = trashDecisions().count
        sortedCount = (try? context.fetchCount(FetchDescriptor<SortDecision>())) ?? 0
    }

    private func save() {
        try? context.save()
    }

    private func preheat() {
        library.startCaching(Array(queue.prefix(4)), targetSize: cacheSize)
    }
}
