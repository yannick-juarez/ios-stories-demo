//
//  StoryViewerViewModel.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 21/04/2026.
//

import Combine
import Foundation

@MainActor
final class StoryViewerViewModel: ObservableObject {
    private enum PendingForwardNavigation {
        case advanceToNextItem
        case jumpToAdjacentStory
    }

    struct StoryTransitionSnapshot {
        let story: Story
        let item: StoryItem
        let currentItemIndex: Int
    }

    struct StoryTransitionInstruction {
        let direction: StoryTransitionDirection
        let snapshot: StoryTransitionSnapshot
    }

    struct ViewerNavigationResult {
        let requestMoreAroundStory: Story?
        let transition: StoryTransitionInstruction?
        let shouldDismiss: Bool
        let shouldResetProgress: Bool

        static let none = ViewerNavigationResult(
            requestMoreAroundStory: nil,
            transition: nil,
            shouldDismiss: false,
            shouldResetProgress: false
        )
    }

    @Published private(set) var stories: [Story]
    @Published var currentStoryIndex: Int
    @Published var currentItemIndex: Int = 0
    private var pendingForwardNavigation: PendingForwardNavigation?
    let prefetchQueueSize: Int

    init(stories: [Story], selectedStoryID: String, prefetchQueueSize: Int = 3) {
        self.stories = stories
        self.currentStoryIndex = stories.firstIndex(where: { $0.id == selectedStoryID }) ?? 0
        self.prefetchQueueSize = max(prefetchQueueSize, 0)
        clampIndices()
    }

    var currentStory: Story {
        stories[safeStoryIndex]
    }

    var currentItem: StoryItem {
        currentStory.items[safeItemIndex(in: currentStory)]
    }

    func updateStories(_ stories: [Story]) {
        guard !stories.isEmpty else { return }

        let currentStoryID = currentStory.id
        self.stories = stories

        if let updatedIndex = stories.firstIndex(where: { $0.id == currentStoryID }) {
            currentStoryIndex = updatedIndex
        } else {
            currentStoryIndex = min(currentStoryIndex, max(stories.count - 1, 0))
        }

        clampIndices()
    }

    func moveToPrevious() {
        guard !stories.isEmpty else { return }

        if currentItemIndex > 0 {
            currentItemIndex -= 1
            return
        }

        guard currentStoryIndex > 0 else { return }
        currentStoryIndex -= 1
        clampIndices()
        currentItemIndex = max(currentStory.items.count - 1, 0)
    }

    func moveToNext() -> Bool {
        guard !stories.isEmpty else { return false }

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

    func canMoveToAdjacentStory(direction: StoryTransitionDirection) -> Bool {
        guard !stories.isEmpty else { return false }

        switch direction {
        case .forward:
            return currentStoryIndex < stories.count - 1
        case .backward:
            return currentStoryIndex > 0
        }
    }

    @discardableResult
    func moveToAdjacentStory(direction: StoryTransitionDirection) -> Bool {
        guard canMoveToAdjacentStory(direction: direction) else { return false }

        switch direction {
        case .forward:
            currentStoryIndex += 1
        case .backward:
            currentStoryIndex -= 1
        }

        currentItemIndex = 0
        clampIndices()
        return true
    }

    func handlePrevious(currentProgress: Double, rewindThreshold: Double = 0.2) -> ViewerNavigationResult {
        guard !stories.isEmpty else { return .none }

        if currentProgress > rewindThreshold {
            return ViewerNavigationResult(
                requestMoreAroundStory: nil,
                transition: nil,
                shouldDismiss: false,
                shouldResetProgress: true
            )
        }

        let shouldAnimateStoryTransition = currentItemIndex == 0 && currentStoryIndex > 0
        let snapshot = shouldAnimateStoryTransition ? currentPositionSnapshot() : nil

        moveToPrevious()

        let transition: StoryTransitionInstruction?
        if let snapshot {
            transition = StoryTransitionInstruction(direction: .backward, snapshot: snapshot)
        } else {
            transition = nil
        }

        return ViewerNavigationResult(
            requestMoreAroundStory: nil,
            transition: transition,
            shouldDismiss: false,
            shouldResetProgress: false
        )
    }

    func handleNext(isLoadingMore: Bool) -> ViewerNavigationResult {
        guard !stories.isEmpty else {
            return ViewerNavigationResult(
                requestMoreAroundStory: nil,
                transition: nil,
                shouldDismiss: true,
                shouldResetProgress: false
            )
        }

        let isLastItemInStory = currentItemIndex == currentStory.items.count - 1
        let hasNextStory = currentStoryIndex < stories.count - 1
        let requestMoreAroundStory = isLastItemInStory ? currentStory : nil
        let snapshot = (isLastItemInStory && hasNextStory) ? currentPositionSnapshot() : nil

        if !moveToNext() {
            if isLastItemInStory, isLoadingMore {
                pendingForwardNavigation = .advanceToNextItem
                return ViewerNavigationResult(
                    requestMoreAroundStory: requestMoreAroundStory,
                    transition: nil,
                    shouldDismiss: false,
                    shouldResetProgress: false
                )
            }

            return ViewerNavigationResult(
                requestMoreAroundStory: requestMoreAroundStory,
                transition: nil,
                shouldDismiss: true,
                shouldResetProgress: false
            )
        }

        let transition: StoryTransitionInstruction?
        if let snapshot {
            transition = StoryTransitionInstruction(direction: .forward, snapshot: snapshot)
        } else {
            transition = nil
        }

        return ViewerNavigationResult(
            requestMoreAroundStory: requestMoreAroundStory,
            transition: transition,
            shouldDismiss: false,
            shouldResetProgress: false
        )
    }

    func handleAdjacentJump(
        direction: StoryTransitionDirection,
        isLoadingMore: Bool
    ) -> ViewerNavigationResult {
        guard !stories.isEmpty else { return .none }

        let requestMoreAroundStory = direction == .forward ? currentStory : nil

        guard canMoveToAdjacentStory(direction: direction) else {
            if direction == .forward, isLoadingMore {
                pendingForwardNavigation = .jumpToAdjacentStory
            }

            return ViewerNavigationResult(
                requestMoreAroundStory: requestMoreAroundStory,
                transition: nil,
                shouldDismiss: false,
                shouldResetProgress: false
            )
        }

        let snapshot = currentPositionSnapshot()
        guard moveToAdjacentStory(direction: direction) else { return .none }

        return ViewerNavigationResult(
            requestMoreAroundStory: requestMoreAroundStory,
            transition: StoryTransitionInstruction(direction: direction, snapshot: snapshot),
            shouldDismiss: false,
            shouldResetProgress: false
        )
    }

    func resolvePendingForwardNavigation(isLoadingMore: Bool) -> ViewerNavigationResult {
        guard let pendingForwardNavigation else { return .none }

        switch pendingForwardNavigation {
        case .advanceToNextItem:
            let snapshot = currentPositionSnapshot()

            if !moveToNext() {
                guard !isLoadingMore else { return .none }
                self.pendingForwardNavigation = nil
                return ViewerNavigationResult(
                    requestMoreAroundStory: nil,
                    transition: nil,
                    shouldDismiss: true,
                    shouldResetProgress: false
                )
            }

            self.pendingForwardNavigation = nil

            let transition: StoryTransitionInstruction?
            if currentItemIndex == 0 {
                transition = StoryTransitionInstruction(direction: .forward, snapshot: snapshot)
            } else {
                transition = nil
            }

            return ViewerNavigationResult(
                requestMoreAroundStory: nil,
                transition: transition,
                shouldDismiss: false,
                shouldResetProgress: false
            )

        case .jumpToAdjacentStory:
            guard canMoveToAdjacentStory(direction: .forward) else {
                if !isLoadingMore {
                    self.pendingForwardNavigation = nil
                }
                return .none
            }

            let snapshot = currentPositionSnapshot()
            self.pendingForwardNavigation = nil
            guard moveToAdjacentStory(direction: .forward) else { return .none }

            return ViewerNavigationResult(
                requestMoreAroundStory: nil,
                transition: StoryTransitionInstruction(direction: .forward, snapshot: snapshot),
                shouldDismiss: false,
                shouldResetProgress: false
            )
        }
    }

    func upcomingImageURLs(limit: Int? = nil) -> [URL] {
        guard !stories.isEmpty else { return [] }

        let prefetchLimit = max(limit ?? prefetchQueueSize, 0)
        guard prefetchLimit > 0 else { return [] }

        var urls: [URL] = []
        var seen: Set<URL> = []
        urls.reserveCapacity(prefetchLimit)

        func appendIfNeeded(_ url: URL) {
            guard urls.count < prefetchLimit else { return }
            guard seen.insert(url).inserted else { return }
            urls.append(url)
        }

        let currentItems = stories[currentStoryIndex].items
        if currentItemIndex + 1 < currentItems.count {
            appendIfNeeded(currentItems[currentItemIndex + 1].imageURL)
        }

        if currentStoryIndex + 1 < stories.count {
            let immediateNextStory = stories[currentStoryIndex + 1]
            if let firstItem = immediateNextStory.items.first {
                appendIfNeeded(firstItem.imageURL)
            }
        }

        let forwardStoryLookahead = min(currentStoryIndex + 3, stories.count - 1)
        if currentStoryIndex + 2 <= forwardStoryLookahead {
            for storyIndex in (currentStoryIndex + 2)...forwardStoryLookahead {
                if let firstItem = stories[storyIndex].items.first {
                    appendIfNeeded(firstItem.imageURL)
                }
            }
        }

        var storyIndex = currentStoryIndex
        var itemIndex = currentItemIndex + 1

        while storyIndex < stories.count, urls.count < prefetchLimit {
            let items = stories[storyIndex].items

            if itemIndex < items.count {
                appendIfNeeded(items[itemIndex].imageURL)
                itemIndex += 1
                continue
            }

            storyIndex += 1
            itemIndex = 0
        }

        return urls
    }

    private var safeStoryIndex: Int {
        min(max(currentStoryIndex, 0), max(stories.count - 1, 0))
    }

    private func safeItemIndex(in story: Story) -> Int {
        min(max(currentItemIndex, 0), max(story.items.count - 1, 0))
    }

    private func clampIndices() {
        guard !stories.isEmpty else {
            currentStoryIndex = 0
            currentItemIndex = 0
            return
        }

        currentStoryIndex = safeStoryIndex
        currentItemIndex = safeItemIndex(in: stories[currentStoryIndex])
    }

    private func currentPositionSnapshot() -> StoryTransitionSnapshot {
        StoryTransitionSnapshot(
            story: currentStory,
            item: currentItem,
            currentItemIndex: currentItemIndex
        )
    }
}
