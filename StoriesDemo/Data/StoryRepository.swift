//
//  StoryRepository.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 21/04/2026.
//

import Foundation

protocol StoryRepositoryProtocol {
    func fetchStories(page: Int, pageSize: Int) -> [Story]
}

struct StoryRepository: StoryRepositoryProtocol {
    private let baseStories: [Story]

    nonisolated init(baseCount: Int = 24, itemsPerStory: Int = 3) {
        self.baseStories = StoryRepository.generateBaseStories(count: baseCount, itemsPerStory: itemsPerStory)
    }

    nonisolated func fetchStories(page: Int, pageSize: Int) -> [Story] {
        guard !baseStories.isEmpty, pageSize > 0 else {
            return []
        }

        let start = page * pageSize
        let end = start + pageSize

        return (start..<end).map { absoluteIndex in
            let template = baseStories[absoluteIndex % baseStories.count]
            return StoryRepository.cloned(template: template, absoluteIndex: absoluteIndex)
        }
    }

    private nonisolated static func cloned(template: Story, absoluteIndex: Int) -> Story {
        let storyID = "story-\(absoluteIndex)-\(template.id)"
        let user = User(
            id: "user-\(absoluteIndex)-\(template.user.id)",
            canonicalID: template.user.canonicalID,
            username: template.user.username,
            avatarURL: template.user.avatarURL
        )

        let items = template.items.enumerated().map { itemIndex, item in
            StoryItem(
                id: "item-\(absoluteIndex)-\(itemIndex)-\(item.id)",
                canonicalID: item.canonicalID,
                imageURL: item.imageURL
            )
        }

        return Story(id: storyID, canonicalID: template.canonicalID, user: user, items: items)
    }

    private nonisolated static func generateBaseStories(count: Int, itemsPerStory: Int) -> [Story] {
        (0..<count).map { index in
            let userID = "base-user-\(index)"
            let username = "user\(index + 1)"

            let user = User(
                id: userID,
                canonicalID: userID,
                username: username,
                avatarURL: seededImageURL(seed: "avatar-base-\(index)", width: 160, height: 160)
            )

            let items = (0..<itemsPerStory).map { itemIndex in
                StoryItem(
                    id: "base-item-\(index)-\(itemIndex)",
                    canonicalID: "base-item-\(index)-\(itemIndex)",
                    imageURL: seededImageURL(seed: "base-story-\(index)-\(itemIndex)", width: 1080, height: 1920)
                )
            }

            return Story(id: "base-story-\(index)", canonicalID: "base-story-\(index)", user: user, items: items)
        }
    }

    private nonisolated static func seededImageURL(seed: String, width: Int, height: Int) -> URL {
        URL(string: "https://picsum.photos/seed/\(seed)/\(width)/\(height)")!
    }
}
