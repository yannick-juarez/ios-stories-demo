import Combine
import Foundation

@MainActor
final class StoryListViewModel: ObservableObject {

    @Published private(set) var stories: [Story] = []

    private let repository: StoryRepositoryProtocol
    private let pageSize: Int
    private var currentPage = 0
    private var isLoading = false

    init(repository: StoryRepositoryProtocol = StoryRepository(), pageSize: Int = 12) {
        self.repository = repository
        self.pageSize = pageSize
    }

    func loadInitialIfNeeded() {
        guard stories.isEmpty else { return }
        loadMoreIfNeeded(currentStory: nil)
    }

    func loadMoreIfNeeded(currentStory: Story?) {
        guard !isLoading else { return }

        if let currentStory {
            let thresholdIndex = max(stories.count - 4, 0)
            guard let currentIndex = stories.firstIndex(where: { $0.id == currentStory.id }),
                  currentIndex >= thresholdIndex else {
                return
            }
        }

        isLoading = true
        let next = repository.fetchStories(page: currentPage, pageSize: pageSize)
        stories.append(contentsOf: next)
        currentPage += 1
        isLoading = false
    }
}
