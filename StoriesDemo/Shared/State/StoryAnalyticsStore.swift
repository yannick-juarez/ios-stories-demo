//
//  StoryAnalyticsStore.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 21/04/2026.
//

import Combine
import Foundation

@MainActor
final class StoryAnalyticsStore: ObservableObject {

    struct ThemeAnalytics: Codable, Hashable {
        var views: Int
        var likes: Int

        static let empty = ThemeAnalytics(views: 0, likes: 0)
    }

    @Published private(set) var analyticsByThemeID: [String: ThemeAnalytics]

    private let defaults: UserDefaults
    private let analyticsKey = "stories.analytics.by-theme"
    private let viewedByThemeKey = "stories.analytics.viewed-story-ids.by-theme"
    private var viewedStoryIDsByThemeID: [String: Set<String>]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.analyticsByThemeID = Self.loadJSON(
            [String: ThemeAnalytics].self,
            from: defaults,
            forKey: analyticsKey
        ) ?? [:]

        let viewedByTheme = Self.loadJSON(
            [String: [String]].self,
            from: defaults,
            forKey: viewedByThemeKey
        ) ?? [:]
        self.viewedStoryIDsByThemeID = viewedByTheme.mapValues { Set($0) }
    }

    func trackView(storyID: String, themeID: String) {
        var viewedStoryIDs = viewedStoryIDsByThemeID[themeID] ?? []
        let insertion = viewedStoryIDs.insert(storyID)
        guard insertion.inserted else { return }

        viewedStoryIDsByThemeID[themeID] = viewedStoryIDs

        var analytics = analyticsByThemeID[themeID] ?? .empty
        analytics.views += 1
        analyticsByThemeID[themeID] = analytics

        persistViewedStoryIDsByTheme()
        persistAnalytics()
    }

    func trackLike(themeID: String) {
        var analytics = analyticsByThemeID[themeID] ?? .empty
        analytics.likes += 1
        analyticsByThemeID[themeID] = analytics
        persistAnalytics()
    }

    func analytics(forThemeID themeID: String) -> ThemeAnalytics {
        analyticsByThemeID[themeID] ?? .empty
    }

    func resetAll() {
        analyticsByThemeID.removeAll()
        viewedStoryIDsByThemeID.removeAll()
        defaults.removeObject(forKey: analyticsKey)
        defaults.removeObject(forKey: viewedByThemeKey)
    }

    private func persistViewedStoryIDsByTheme() {
        let payload = viewedStoryIDsByThemeID.mapValues { Array($0) }
        persistJSON(payload, forKey: viewedByThemeKey)
    }

    private func persistAnalytics() {
        persistJSON(analyticsByThemeID, forKey: analyticsKey)
    }

    private func persistJSON<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private static func loadJSON<T: Decodable>(
        _ type: T.Type,
        from defaults: UserDefaults,
        forKey key: String
    ) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
