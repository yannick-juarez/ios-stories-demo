//
//  StoryStateStore.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 21/04/2026.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class StoryStateStore: ObservableObject {

    @Published private(set) var seenStoryIDs: Set<String>
    @Published private(set) var likedItemIDs: Set<String>

    private let defaults: UserDefaults
    private let seenKey = "stories.seen.ids"
    private let likedKey = "stories.liked.ids"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.seenStoryIDs = Set(defaults.stringArray(forKey: seenKey) ?? [])
        self.likedItemIDs = Set(defaults.stringArray(forKey: likedKey) ?? [])
    }

    func isSeen(storyID: String) -> Bool {
        seenStoryIDs.contains(storyID)
    }

    func markSeen(storyID: String) {
        guard !seenStoryIDs.contains(storyID) else { return }
        seenStoryIDs.insert(storyID)
        persistSeen()
    }

    func isLiked(itemID: String) -> Bool {
        likedItemIDs.contains(itemID)
    }

    @discardableResult
    func toggleLike(itemID: String) -> Bool {
        if likedItemIDs.contains(itemID) {
            likedItemIDs.remove(itemID)
            persistLiked()
            return false
        } else {
            likedItemIDs.insert(itemID)
            persistLiked()
            return true
        }
    }

    func storyHasLikedItems(_ story: Story) -> Bool {
        story.items.contains { likedItemIDs.contains($0.canonicalID) }
    }

    func resetAll() {
        seenStoryIDs.removeAll()
        likedItemIDs.removeAll()
        defaults.removeObject(forKey: seenKey)
        defaults.removeObject(forKey: likedKey)
    }

    private func persistSeen() {
        defaults.set(Array(seenStoryIDs), forKey: seenKey)
    }

    private func persistLiked() {
        defaults.set(Array(likedItemIDs), forKey: likedKey)
    }
}
