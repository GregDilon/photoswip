import Photos
import SwiftUI

/// Affiche l'écran adapté selon l'autorisation d'accès à la photothèque.
struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var status = PhotoLibraryService.shared.authorizationStatus

    var body: some View {
        Group {
            switch status {
            case .authorized:
                SortingView(isLimitedAccess: false)
            case .limited:
                SortingView(isLimitedAccess: true)
            case .notDetermined:
                PermissionView(isDenied: false) {
                    status = await PhotoLibraryService.shared.requestAuthorization()
                }
            default:
                PermissionView(isDenied: true) {}
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // L'utilisateur a pu changer l'autorisation dans Réglages.
            if phase == .active {
                status = PhotoLibraryService.shared.authorizationStatus
            }
        }
    }
}
