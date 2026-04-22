//
//  StoryPreviewContainer.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 22/04/2026.
//

import SwiftUI

struct StoryPreviewContainer<Content: View>: View {

    @StateObject private var listViewModel = StoryListViewModel()
    @StateObject private var stateStore = StoryStateStore()
    @StateObject private var analyticsStore = StoryAnalyticsStore()
    @StateObject private var themeStore = ThemeStore()

    private let content: (StoryListViewModel, Story, StoryItem, Theme) -> Content

    init(@ViewBuilder content: @escaping (Story) -> Content) {
        self.content = { _, story, _, _ in
            content(story)
        }
    }

    init(@ViewBuilder withDependencies content: @escaping (StoryListViewModel, Story, StoryItem, Theme) -> Content) {
        self.content = content
    }

    var body: some View {
        Group {
            if let firstStory = listViewModel.stories.first {
                let firstItem = firstStory.items.first ?? .sample
                content(listViewModel, firstStory, firstItem, themeStore.currentTheme)
            } else {
                Color.black
            }
        }
        .task {
            listViewModel.loadInitialIfNeeded()
        }
        .environmentObject(stateStore)
        .environmentObject(analyticsStore)
        .environmentObject(themeStore)
    }
}
