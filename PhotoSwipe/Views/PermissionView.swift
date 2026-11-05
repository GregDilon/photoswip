import SwiftUI

struct PermissionView: View {
    let isDenied: Bool
    let onRequest: () async -> Void

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "photo.stack")
                .font(.system(size: 72))
                .foregroundStyle(.tint)

            VStack(spacing: 12) {
                Text("Triez vos photos d'un geste")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text(isDenied
                     ? "L'accès aux photos a été refusé. Autorisez-le dans Réglages pour commencer le tri."
                     : "Glissez à gauche pour supprimer, à droite pour garder. Tout reste sur votre iPhone.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            Spacer()

            Button {
                if isDenied {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                } else {
                    Task { await onRequest() }
                }
            } label: {
                Text(isDenied ? "Ouvrir Réglages" : "Autoriser l'accès aux photos")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
        }
        .padding(24)
    }
}

#Preview {
    PermissionView(isDenied: false) {}
}
