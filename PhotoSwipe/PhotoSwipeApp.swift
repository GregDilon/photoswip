import SwiftData
import SwiftUI

@main
struct PhotoSwipeApp: App {
    private let container: ModelContainer
    @State private var viewModel: SortingViewModel

    init() {
        do {
            let container = try ModelContainer(for: SortDecision.self)
            self.container = container
            _viewModel = State(initialValue: SortingViewModel(context: container.mainContext))
        } catch {
            fatalError("Impossible de créer la base SwiftData : \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(viewModel)
        }
        .modelContainer(container)
    }
}
