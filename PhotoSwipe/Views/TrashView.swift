import Photos
import SwiftUI

struct TrashView: View {
    @Environment(SortingViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @State private var assets: [PHAsset] = []
    @State private var isDeleting = false
    @State private var confirmEmpty = false

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 2)]

    var body: some View {
        NavigationStack {
            Group {
                if assets.isEmpty {
                    ContentUnavailableView("Corbeille vide", systemImage: "trash",
                                           description: Text("Les photos glissées à gauche apparaîtront ici."))
                } else {
                    ScrollView {
                        Text("Touchez une photo pour la récupérer.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(assets, id: \.localIdentifier) { asset in
                                thumbnail(asset)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Corbeille")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !assets.isEmpty {
                    Button(role: .destructive) {
                        confirmEmpty = true
                    } label: {
                        Group {
                            if isDeleting {
                                ProgressView()
                            } else {
                                Text("Supprimer \(assets.count) photo\(assets.count > 1 ? "s" : "")")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .controlSize(.large)
                    .disabled(isDeleting)
                    .padding()
                    .background(.bar)
                }
            }
            .confirmationDialog("Supprimer ces photos ?", isPresented: $confirmEmpty, titleVisibility: .visible) {
                Button("Supprimer \(assets.count) photo\(assets.count > 1 ? "s" : "")", role: .destructive) {
                    Task { await empty() }
                }
            } message: {
                Text("Elles resteront 30 jours dans « Supprimés récemment » de l'app Photos.")
            }
        }
        .task { assets = viewModel.trashedAssets() }
    }

    private func thumbnail(_ asset: PHAsset) -> some View {
        Button {
            withAnimation {
                viewModel.restore(asset)
                assets.removeAll { $0.localIdentifier == asset.localIdentifier }
            }
        } label: {
            AssetImageView(asset: asset, contentMode: .fill)
                .aspectRatio(1, contentMode: .fit)
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.5))
                        .padding(6)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Récupérer cette photo")
    }

    private func empty() async {
        isDeleting = true
        let deleted = await viewModel.emptyTrash()
        isDeleting = false
        if deleted {
            assets = []
            dismiss()
        }
    }
}
