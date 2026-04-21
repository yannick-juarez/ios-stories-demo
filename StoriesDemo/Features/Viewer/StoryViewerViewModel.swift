import Combine
import Foundation

@MainActor
final class StoryViewerViewModel: ObservableObject {
    @Published private(set) var stories: [Story]
    @Published var currentStoryIndex: Int
    @Published var currentItemIndex: Int = 0

    init(stories: [Story], selectedStoryID: String) {
        self.stories = stories
        self.currentStoryIndex = stories.firstIndex(where: { $0.id == selectedStoryID }) ?? 0
    }

    var currentStory: Story {
        stories[currentStoryIndex]
    }

    var currentItem: StoryItem {
        currentStory.items[currentItemIndex]
    }

    func updateStories(_ stories: [Story]) {
        let currentStoryID = currentStory.id
        self.stories = stories

        if let updatedIndex = stories.firstIndex(where: { $0.id == currentStoryID }) {
            currentStoryIndex = updatedIndex
            currentItemIndex = min(currentItemIndex, stories[updatedIndex].items.count - 1)
        } else {
            currentStoryIndex = min(currentStoryIndex, max(stories.count - 1, 0))
            currentItemIndex = min(currentItemIndex, stories[currentStoryIndex].items.count - 1)
        }
    }

    func moveToPrevious() {
        if currentItemIndex > 0 {
            currentItemIndex -= 1
            return
        }

        guard currentStoryIndex > 0 else { return }
        currentStoryIndex -= 1
        currentItemIndex = max(stories[currentStoryIndex].items.count - 1, 0)
    }

    func moveToNext() -> Bool {
        if currentItemIndex < currentStory.items.count - 1 {
            currentItemIndex += 1
            return true
        }

        if currentStoryIndex < stories.count - 1 {
            currentStoryIndex += 1
            currentItemIndex = 0
            return true
        }

        return false
    }
}
