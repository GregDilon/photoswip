import Photos
import SwiftUI

struct SortingView: View {
    let isLimitedAccess: Bool

    @Environment(SortingViewModel.self) private var viewModel
    @State private var dragOffset: CGSize = .zero
    @State private var isAnimatingOut = false
    @State private var showTrash = false

    private let threshold: CGFloat = 120

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                filterBar
                if isLimitedAccess { limitedBanner }
                cardStack
                controls
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            .navigationTitle("PhotoSwipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showTrash = true } label: {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.trashCount > 0 ? "trash.fill" : "trash")
                            if viewModel.trashCount > 0 {
                                Text("\(viewModel.trashCount)")
                                    .monospacedDigit()
                            }
                        }
                        .foregroundStyle(viewModel.trashCount > 0 ? .red : .primary)
                    }
                    .accessibilityLabel("Corbeille, \(viewModel.trashCount) photos")
                }
            }
            .sheet(isPresented: $showTrash) {
                TrashView()
            }
        }
        .task { viewModel.reload() }
    }

    // MARK: - Filtres

    private var filterBar: some View {
        HStack(spacing: 8) {
            ForEach(MediaCategory.allCases) { category in
                let isOn = viewModel.selectedCategories.contains(category)
                Button {
                    if isOn {
                        viewModel.selectedCategories.remove(category)
                    } else {
                        viewModel.selectedCategories.insert(category)
                    }
                } label: {
                    Label(category.title, systemImage: category.systemImage)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(isOn ? Color.accentColor : Color(.secondarySystemFill)))
                        .foregroundStyle(isOn ? .white : .primary)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
            Spacer()
            Text("\(viewModel.queue.count) à trier")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private var limitedBanner: some View {
        Label("Accès limité : seules les photos autorisées sont proposées.", systemImage: "info.circle")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Cartes

    private var cardStack: some View {
        ZStack {
            if viewModel.queue.isEmpty {
                emptyState
            } else {
                let visible = Array(viewModel.queue.prefix(3).enumerated())
                ForEach(visible.reversed(), id: \.element.localIdentifier) { index, asset in
                    if index == 0 {
                        SwipeCardView(asset: asset, offset: dragOffset, threshold: threshold)
                            .gesture(dragGesture)
                            .zIndex(1)
                    } else {
                        SwipeCardView(asset: asset)
                            .scaleEffect(1 - CGFloat(index) * 0.04)
                            .offset(y: CGFloat(index) * 10)
                            .allowsHitTesting(false)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var emptyState: some View {
        if viewModel.selectedCategories.isEmpty {
            ContentUnavailableView("Aucun filtre", systemImage: "line.3.horizontal.decrease.circle",
                                   description: Text("Sélectionnez au moins une catégorie."))
        } else {
            ContentUnavailableView {
                Label("Tout est trié !", systemImage: "checkmark.seal")
            } description: {
                Text(viewModel.trashCount > 0
                     ? "Il reste \(viewModel.trashCount) photos dans la corbeille."
                     : "Plus aucune photo à trier dans ces catégories.")
            } actions: {
                if viewModel.trashCount > 0 {
                    Button("Ouvrir la corbeille") { showTrash = true }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard !isAnimatingOut else { return }
                dragOffset = value.translation
            }
            .onEnded { value in
                guard !isAnimatingOut else { return }
                let width = value.translation.width
                let predicted = value.predictedEndTranslation.width
                if width > threshold || predicted > threshold * 2 {
                    swipe(.keep)
                } else if width < -threshold || predicted < -threshold * 2 {
                    swipe(.trash)
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { dragOffset = .zero }
                }
            }
    }

    // MARK: - Boutons

    private var controls: some View {
        HStack(spacing: 32) {
            roundButton(systemImage: "xmark", color: .red, size: 64) { swipe(.trash) }
                .accessibilityLabel("Supprimer")
            roundButton(systemImage: "arrow.uturn.backward", color: .orange, size: 48) { undo() }
                .disabled(!viewModel.canUndo)
                .opacity(viewModel.canUndo ? 1 : 0.4)
                .accessibilityLabel("Annuler")
            roundButton(systemImage: "heart.fill", color: .green, size: 64) { swipe(.keep) }
                .accessibilityLabel("Garder")
        }
        .disabled(viewModel.queue.isEmpty && !viewModel.canUndo)
    }

    private func roundButton(systemImage: String, color: Color, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(color)
                .frame(width: size, height: size)
                .background(Circle().fill(Color(.systemBackground)))
                .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func swipe(_ decision: Decision) {
        guard !viewModel.queue.isEmpty, !isAnimatingOut else { return }
        isAnimatingOut = true
        let direction: CGFloat = decision == .keep ? 1 : -1
        withAnimation(.easeOut(duration: 0.25)) {
            dragOffset = CGSize(width: direction * 600, height: dragOffset.height)
        } completion: {
            viewModel.decide(decision)
            dragOffset = .zero
            isAnimatingOut = false
        }
    }

    private func undo() {
        guard !isAnimatingOut else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            viewModel.undo()
        }
    }
}
