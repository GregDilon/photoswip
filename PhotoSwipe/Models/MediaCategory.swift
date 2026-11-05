import Foundation

/// Catégories utilisables comme filtres sur la pile de tri.
enum MediaCategory: String, CaseIterable, Identifiable, Hashable {
    case photo
    case screenshot

    var id: String { rawValue }

    var title: String {
        switch self {
        case .photo: "Photos"
        case .screenshot: "Screenshots"
        }
    }

    var systemImage: String {
        switch self {
        case .photo: "photo"
        case .screenshot: "camera.viewfinder"
        }
    }
}
