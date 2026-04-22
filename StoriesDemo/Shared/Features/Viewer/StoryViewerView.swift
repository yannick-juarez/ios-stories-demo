//
//  StoryViewerView.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 21/04/2026.
//

import SwiftUI
import Combine
import UIKit

struct StoryViewerView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.displayScale) private var displayScale
    @EnvironmentObject private var stateStore: StoryStateStore
    @EnvironmentObject private var analyticsStore: StoryAnalyticsStore
    @EnvironmentObject private var themeStore: ThemeStore

    @ObservedObject private var listViewModel: StoryListViewModel
    @StateObject private var viewModel: StoryViewerViewModel
    @State private var currentProgress: Double = 0
    @State private var isCurrentImageReady = false
    @State private var storyTransitionDirection: StoryTransitionDirection = .forward
    @State private var isStoryTransitionInFlight = false
    @State private var outgoingPage: StoryPageSnapshot?
    @State private var viewerWidth: CGFloat = 0
    @State private var viewerHeight: CGFloat = 0
    @State private var incomingPageState = StoryTransition.PageState.identity()
    @State private var outgoingPageState = StoryTransition.PageState.identity()
    @State private var lastTickDate: Date?
    @State private var dismissKeyboardRequested: Bool = false
    @State private var isReplyFocused: Bool = false
    @State private var isHoldActive: Bool = false

    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    private let itemDuration: Double = 4.5

    init(listViewModel: StoryListViewModel, selectedStoryID: String) {
        self._listViewModel = ObservedObject(wrappedValue: listViewModel)
        let viewerViewModel = StoryViewerViewModel(
            stories: listViewModel.stories,
            selectedStoryID: selectedStoryID
        )
        _viewModel = StateObject(wrappedValue: viewerViewModel)
        _prefetchStrategy = StateObject(
            wrappedValue: PrefetchStrategyManager()
        )
    }

    @StateObject private var prefetchStrategy: PrefetchStrategyManager

    private var theme: Theme {
        themeStore.currentTheme
    }

    private var stories: [Story] {
        listViewModel.stories
    }

    private var currentStory: Story {
        viewModel.currentStory
    }

    private var currentItem: StoryItem {
        viewModel.currentItem
    }

    private var storyTransition: StoryTransition {
        theme.viewer.transition
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                theme.viewer.backgroundColor
                    .ignoresSafeArea()

                if let outgoingPage {
                    StoryPageContent(
                        story: outgoingPage.story,
                        item: outgoingPage.item,
                        safeAreaInsets: proxy.safeAreaInsets,
                        currentItemIndex: outgoingPage.currentItemIndex,
                        currentProgress: outgoingPage.currentProgress,
                        isLiked: outgoingPage.isLiked,
                        theme: theme,
                        allowsInteraction: false,
                        onImageReady: { _ in },
                        onPrevious: {},
                        onNext: {},
                        onDismiss: {},
                        onToggleLike: {},
                        dismissKeyboardRequested: .constant(false),
                        isReplyFocused: .constant(false),
                        isHoldActive: .constant(false)
                    )
                    .modifier(
                        StoryTransitionPageModifier(state: outgoingPageState)
                    )
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .zIndex(1)
                }

                StoryPage(safeAreaInsets: proxy.safeAreaInsets)
                    .modifier(
                        StoryTransitionPageModifier(state: incomingPageState)
                    )
                    .ignoresSafeArea()
                    .zIndex(0)

            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .onAppear {
                viewerWidth = proxy.size.width
                viewerHeight = proxy.size.height
                refreshPrefetchQueue()
            }
            .onChange(of: proxy.size.width) { _, newWidth in
                viewerWidth = newWidth
                refreshPrefetchQueue()
            }
            .onChange(of: proxy.size.height) { _, newHeight in
                viewerHeight = newHeight
                refreshPrefetchQueue()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    handleViewerDrag(value)
                }
        )
        .onReceive(timer) { now in
            tickProgress(now: now)
        }
        .onChange(of: listViewModel.stories) { _, stories in
            guard !stories.isEmpty else { return }
            viewModel.updateStories(stories)
            resolvePendingForwardNavigationIfNeeded()
            refreshPrefetchQueue()
        }
        .onChange(of: listViewModel.isLoading) { _, isLoading in
            guard !isLoading else { return }
            resolvePendingForwardNavigationIfNeeded()
        }
        .task {
            viewModel.updateStories(stories)
            stateStore.markSeen(storyID: currentStory.canonicalID)
            analyticsStore.trackView(storyID: currentStory.canonicalID, themeID: theme.id)
            maybeRequestMoreStories(around: currentStory)
            refreshPrefetchQueue()
        }
        .onChange(of: viewModel.currentStoryIndex) { _, _ in
            isHoldActive = false
            dismissKeyboardRequested = true
            resetCurrentProgress()
            stateStore.markSeen(storyID: currentStory.canonicalID)
            analyticsStore.trackView(storyID: currentStory.canonicalID, themeID: theme.id)
            maybeRequestMoreStories(around: currentStory)
            refreshPrefetchQueue()
        }
        .onChange(of: viewModel.currentItemIndex) { _, _ in
            isHoldActive = false
            dismissKeyboardRequested = true
            resetCurrentProgress()
            refreshPrefetchQueue()
        }
        .onChange(of: effectivePrefetchQueueSize) { _, _ in
            refreshPrefetchQueue()
        }
    }

    private func StoryPage(safeAreaInsets: EdgeInsets) -> some View {
        StoryPageContent(
            story: currentStory,
            item: currentItem,
            safeAreaInsets: safeAreaInsets,
            currentItemIndex: viewModel.currentItemIndex,
            currentProgress: currentProgress,
            isLiked: stateStore.isLiked(itemID: currentItem.canonicalID),
            theme: theme,
            allowsInteraction: !isStoryTransitionInFlight,
            onImageReady: { isReady in
                isCurrentImageReady = isReady
            },
            onPrevious: {
                goPrevious()
            },
            onNext: {
                goNextOrDismiss()
            },
            onDismiss: {
                dismiss()
            },
            onToggleLike: {
                let isLiked = stateStore.toggleLike(itemID: currentItem.canonicalID)
                if isLiked {
                    analyticsStore.trackLike(themeID: theme.id)
                }
            },
            dismissKeyboardRequested: $dismissKeyboardRequested,
            isReplyFocused: $isReplyFocused,
            isHoldActive: $isHoldActive
        )
    }

    private func tickProgress(now: Date) {
        guard scenePhase == .active,
              isCurrentImageReady,
              !isStoryTransitionInFlight,
              !isReplyFocused,
              !isHoldActive else {
            lastTickDate = nil
            return
        }

        let delta = now.timeIntervalSince(lastTickDate ?? now)
        lastTickDate = now

        guard delta > 0 else { return }

        let normalizedStep = min(delta / itemDuration, 0.25)
        currentProgress = min(currentProgress + normalizedStep, 1)

        if currentProgress >= 1 {
            goNextOrDismiss()
        }
    }

    private func resetCurrentProgress() {
        var transaction = Transaction()
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            currentProgress = 0
            isCurrentImageReady = false
            lastTickDate = nil
        }
    }

    private func goPrevious() {
        guard !isStoryTransitionInFlight else { return }

        let result = viewModel.handlePrevious(currentProgress: currentProgress)
        applyNavigationResult(result)
    }

    private func goNextOrDismiss() {
        guard !isStoryTransitionInFlight else { return }

        let result = viewModel.handleNext(isLoadingMore: listViewModel.isLoading)
        applyNavigationResult(result)
    }

    private func prepareStoryTransition(
        direction: StoryTransitionDirection,
        snapshot: StoryViewerViewModel.StoryTransitionSnapshot
    ) {
        let width = cubeTravelDistance
        let states = storyTransition.preparedStates(direction: direction, width: width)

        storyTransitionDirection = direction
        outgoingPage = StoryPageSnapshot(
            story: snapshot.story,
            item: snapshot.item,
            currentItemIndex: snapshot.currentItemIndex,
            currentProgress: currentProgress,
            isLiked: stateStore.isLiked(itemID: snapshot.item.canonicalID)
        )

        incomingPageState = states.incoming
        outgoingPageState = states.outgoing
    }

    private func startStoryTransition() {
        guard !isStoryTransitionInFlight, outgoingPage != nil else { return }

        isStoryTransitionInFlight = true

        let width = cubeTravelDistance
        let states = storyTransition.finalStates(direction: storyTransitionDirection, width: width)

        withAnimation(storyTransition.animation) {
            incomingPageState = states.incoming
            outgoingPageState = states.outgoing
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + storyTransition.duration) {
            resetStoryTransitionState()
            isStoryTransitionInFlight = false
        }
    }

    private func resetStoryTransitionState() {
        outgoingPage = nil
        outgoingPageState = StoryTransition.PageState.identity()
        incomingPageState = StoryTransition.PageState.identity()
    }

    private var cubeTravelDistance: CGFloat {
        max(viewerWidth, 1)
    }

    private func refreshPrefetchQueue() {
        guard viewerWidth > 0, viewerHeight > 0 else { return }

        StoryImageLoader.updatePrefetchQueue(
            with: viewModel.upcomingImageURLs(limit: effectivePrefetchQueueSize),
            queueSize: effectivePrefetchQueueSize,
            targetSize: CGSize(width: viewerWidth, height: viewerHeight),
            displayScale: displayScale
        )
    }

    private func handleViewerDrag(_ value: DragGesture.Value) {
        guard !isStoryTransitionInFlight else { return }

        let horizontal = abs(value.translation.width) > abs(value.translation.height)

        if horizontal {
            handleHorizontalSwipe(value)
        } else {
            handleVerticalGesture(value)
        }
    }

    private func handleHorizontalSwipe(_ value: DragGesture.Value) {
        let width = value.translation.width
        let projectedWidth = value.predictedEndTranslation.width

        if width <= -80 || projectedWidth <= -140 {
            jumpToAdjacentStory(direction: .forward)
            return
        }

        if width >= 80 || projectedWidth >= 140 {
            jumpToAdjacentStory(direction: .backward)
        }
    }

    private func handleVerticalGesture(_ value: DragGesture.Value) {
        let height = value.translation.height
        let projectedHeight = value.predictedEndTranslation.height

        let shouldFocusReply = height < -100 || projectedHeight < -180
        if shouldFocusReply {
            NotificationCenter.default.post(name: Notification.Name("storyReplyFocusRequested"), object: nil)
            return
        }

        let shouldDismiss = height > 120 || projectedHeight > 220
        if shouldDismiss {
            if isReplyFocused {
                dismissKeyboardRequested = true
            } else {
                dismiss()
            }
        }
    }

    private func jumpToAdjacentStory(direction: StoryTransitionDirection) {
        let result = viewModel.handleAdjacentJump(
            direction: direction,
            isLoadingMore: listViewModel.isLoading
        )
        applyNavigationResult(result)
    }

    private func maybeRequestMoreStories(around story: Story) {
        listViewModel.loadMoreIfNeeded(currentStory: story)
        viewModel.updateStories(stories)
    }

    private func resolvePendingForwardNavigationIfNeeded() {
        let result = viewModel.resolvePendingForwardNavigation(isLoadingMore: listViewModel.isLoading)
        applyNavigationResult(result)
    }

    private func applyNavigationResult(_ result: StoryViewerViewModel.ViewerNavigationResult) {
        if let story = result.requestMoreAroundStory {
            maybeRequestMoreStories(around: story)
        }

        if result.shouldResetProgress {
            currentProgress = 0
            return
        }

        if let transition = result.transition {
            prepareStoryTransition(direction: transition.direction, snapshot: transition.snapshot)
            startStoryTransition()
            return
        }

        if result.shouldDismiss {
            dismiss()
        }
    }

    private var effectivePrefetchQueueSize: Int {
        prefetchStrategy.effectivePrefetchQueueSize
    }
}

private struct StoryPageSnapshot: Identifiable {
    let id = UUID()
    let story: Story
    let item: StoryItem
    let currentItemIndex: Int
    let currentProgress: Double
    let isLiked: Bool
}


// MARK: - Previews

#Preview {
    StoryPreviewContainer(withDependencies: { listViewModel, story, _, _ in
        StoryViewerView(listViewModel: listViewModel, selectedStoryID: story.id)
    })
}
