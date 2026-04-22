//
//  StoryListView.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 22/04/2026.
//

import SwiftUI

struct StoryListView: View {

    @EnvironmentObject private var stateStore: StoryStateStore
    @EnvironmentObject private var analyticsStore: StoryAnalyticsStore
    @EnvironmentObject private var themeStore: ThemeStore

    @StateObject private var listViewModel = StoryListViewModel()
    @State private var selectedStory: Story?
    @Namespace private var zoomNamespace

    private var theme: Theme { themeStore.currentTheme }

    // MARK: - Body
    var body: some View {
        if #available(iOS 18.0, *) {
            bubbleList
                .navigationDestination(item: $selectedStory) { story in
                    StoryViewerView(listViewModel: listViewModel, selectedStoryID: story.id)
                        .environmentObject(stateStore)
                        .environmentObject(analyticsStore)
                        .environmentObject(themeStore)
                        .toolbar(.hidden, for: .navigationBar)
                        .navigationTransition(.zoom(sourceID: story.id, in: zoomNamespace))
                }
        } else {
            bubbleList
                .fullScreenCover(item: $selectedStory) { story in
                    StoryViewerView(listViewModel: listViewModel, selectedStoryID: story.id)
                        .environmentObject(stateStore)
                        .environmentObject(analyticsStore)
                        .environmentObject(themeStore)
                }
        }
    }

    // MARK: - Bubble List
    
    private var bubbleList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: theme.list.bubbleSpacing) {
                ForEach(listViewModel.stories) { story in
                    StoryBubbleView(
                        story: story,
                        isSeen: stateStore.isSeen(storyID: story.canonicalID),
                        hasLike: stateStore.storyHasLikedItems(story)
                    )
                    .matchedTransitionSourceIfAvailable(id: story.id, in: zoomNamespace)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedStory = story
                    }
                    .onAppear {
                        listViewModel.loadMoreIfNeeded(currentStory: story)
                    }
                }
            }
            .padding(.horizontal, theme.list.horizontalPadding)
            .padding(.vertical, theme.list.verticalPadding)
        }
        .scrollClipDisabled()
        .task {
            listViewModel.loadInitialIfNeeded()
        }
    }
}

// MARK: - View helpers

private extension View {
    @ViewBuilder
    func matchedTransitionSourceIfAvailable<ID: Hashable>(id: ID, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            self.matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }
}

// MARK: - Previews

#Preview {
    StoryListViewPreviewContainer()
}

private struct StoryListViewPreviewContainer: View {
    var body: some View {
        NavigationStack {
            StoryListView()
                .environmentObject(StoryStateStore())
                .environmentObject(StoryAnalyticsStore())
                .environmentObject(ThemeStore())
        }
    }
}
