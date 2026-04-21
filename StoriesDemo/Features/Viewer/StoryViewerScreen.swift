import SwiftUI
import Combine
import UIKit

private enum StoryTransitionDirection {
    case forward
    case backward
}

private struct CubePageModifier: ViewModifier {
    let rotation: Double
    let anchor: UnitPoint
    let offset: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .compositingGroup()
            .rotation3DEffect(
                .degrees(rotation),
                axis: (x: 0, y: 1, z: 0),
                anchor: anchor,
                perspective: 0.72
            )
            .offset(x: offset)
            .opacity(opacity)
    }
}

private struct StoryPageContent: View {
    let item: StoryItem
    let chromeColor: Color
    let onImageReady: (Bool) -> Void
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        ZStack {
            StoryImage(
                item: item,
                chromeColor: chromeColor,
                onImageReady: onImageReady
            )

            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onPrevious()
                    }

                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onNext()
                    }
            }
        }
    }
}

@MainActor
private final class StoryImageLoader: ObservableObject {
    @Published private(set) var image: UIImage?
    @Published private(set) var isLoading = false
    @Published private(set) var didFail = false

    private static let cache = NSCache<NSURL, UIImage>()

    private var currentURL: URL?
    private var task: Task<Void, Never>?

    deinit {
        task?.cancel()
    }

    func load(from url: URL) {
        if currentURL == url, image != nil || isLoading || didFail {
            return
        }

        task?.cancel()
        currentURL = url
        didFail = false

        if let cachedImage = Self.cache.object(forKey: url as NSURL) {
            image = cachedImage
            isLoading = false
            return
        }

        image = nil
        isLoading = true

        task = Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)

                guard !Task.isCancelled, let downloadedImage = UIImage(data: data) else {
                    return
                }

                Self.cache.setObject(downloadedImage, forKey: url as NSURL)
                image = downloadedImage
                isLoading = false
            } catch {
                guard !Task.isCancelled else { return }
                didFail = true
                isLoading = false
            }
        }
    }
}

private struct StoryImage: View {
    let item: StoryItem
    let chromeColor: Color
    let onImageReady: (Bool) -> Void

    @StateObject private var loader = StoryImageLoader()

    var body: some View {
        Group {
            if let image = loader.image {
                GeometryReader { proxy in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .onAppear {
                            onImageReady(true)
                        }
                }
            } else if loader.didFail {
                Color.gray.opacity(0.45)
                    .overlay {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.largeTitle)
                            .foregroundStyle(chromeColor)
                    }
                    .onAppear {
                        onImageReady(true)
                    }
            } else {
                ProgressView()
                    .tint(chromeColor)
                    .scaleEffect(1.2)
                    .onAppear {
                        onImageReady(false)
                    }
            }
        }
        .task(id: item.imageURL) {
            loader.load(from: item.imageURL)
        }
    }
}

private struct StoryPageSnapshot: Identifiable {
    let id = UUID()
    let item: StoryItem
}

struct StoryViewerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var stateStore: StoryStateStore
    @EnvironmentObject private var themeStore: ThemeStore

    @ObservedObject private var listViewModel: StoryListViewModel
    @StateObject private var viewModel: StoryViewerViewModel
    @State private var currentProgress: Double = 0
    @State private var isCurrentImageReady = false
    @State private var storyTransitionDirection: StoryTransitionDirection = .forward
    @State private var outgoingPage: StoryPageSnapshot?
    @State private var viewerWidth: CGFloat = 0
    @State private var incomingPageRotation: Double = 0
    @State private var incomingPageOffset: CGFloat = 0
    @State private var incomingPageAnchor: UnitPoint = .leading
    @State private var outgoingPageRotation: Double = 0
    @State private var outgoingPageOffset: CGFloat = 0
    @State private var outgoingPageAnchor: UnitPoint = .trailing

    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    private let itemDuration: Double = 4.5
    private let transitionDuration: Double = 0.42

    init(listViewModel: StoryListViewModel, selectedStoryID: String) {
        self._listViewModel = ObservedObject(wrappedValue: listViewModel)
        _viewModel = StateObject(
            wrappedValue: StoryViewerViewModel(
                stories: listViewModel.stories,
                selectedStoryID: selectedStoryID
            )
        )
    }

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

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                theme.viewer.backgroundColor
                    .ignoresSafeArea()

                if let outgoingPage {
                    StoryPageContent(
                        item: outgoingPage.item,
                        chromeColor: theme.viewer.chromeColor,
                        onImageReady: { _ in },
                        onPrevious: {},
                        onNext: {}
                    )
                    .modifier(
                        CubePageModifier(
                            rotation: outgoingPageRotation,
                            anchor: outgoingPageAnchor,
                            offset: outgoingPageOffset,
                            opacity: 1
                        )
                    )
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .zIndex(1)
                }

                storyPage
                    .modifier(
                        CubePageModifier(
                            rotation: incomingPageRotation,
                            anchor: incomingPageAnchor,
                            offset: incomingPageOffset,
                            opacity: 1
                        )
                    )
                    .ignoresSafeArea()
                    .zIndex(0)

                topOverlay
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    .frame(maxHeight: .infinity, alignment: .top)

                bottomOverlay
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .onAppear {
                viewerWidth = proxy.size.width
            }
            .onChange(of: proxy.size.width) { _, newWidth in
                viewerWidth = newWidth
            }
        }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.height > 120 {
                        dismiss()
                    }
                }
        )
        .onReceive(timer) { _ in
            tickProgress()
        }
        .onChange(of: listViewModel.stories) { _, stories in
            guard !stories.isEmpty else { return }
            viewModel.updateStories(stories)
        }
        .task {
            viewModel.updateStories(stories)
            stateStore.markSeen(storyID: currentStory.canonicalID)
            listViewModel.loadMoreIfNeeded(currentStory: currentStory)
        }
        .onChange(of: viewModel.currentStoryIndex) { _, _ in
            resetCurrentProgress()
            stateStore.markSeen(storyID: currentStory.canonicalID)
            listViewModel.loadMoreIfNeeded(currentStory: currentStory)
        }
        .onChange(of: viewModel.currentItemIndex) { _, _ in
            resetCurrentProgress()
        }
    }

    private var storyPage: some View {
        StoryPageContent(
            item: currentItem,
            chromeColor: theme.viewer.chromeColor,
            onImageReady: { isReady in
                isCurrentImageReady = isReady
            },
            onPrevious: {
                goPrevious()
            },
            onNext: {
                goNextOrDismiss()
            }
        )
    }

    private var topOverlay: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                ForEach(Array(currentStory.items.enumerated()), id: \.offset) { index, _ in
                    GeometryReader { proxy in
                        let width = proxy.size.width

                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(theme.viewer.progressTrackColor)

                            Capsule()
                                .fill(theme.viewer.progressFillColor)
                                .frame(width: width * progress(for: index))
                        }
                    }
                    .frame(height: 3)
                }
            }

            HStack(spacing: 10) {
                AsyncImage(url: currentStory.user.avatarURL) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 34, height: 34)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(theme.viewer.chromeColor.opacity(0.2))
                            .frame(width: 34, height: 34)
                    }
                }

                Text(currentStory.user.username)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.viewer.chromeColor)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(theme.viewer.chromeColor)
                }
            }
        }
    }

    private var bottomOverlay: some View {
        HStack {
            Spacer()

            let isLiked = stateStore.isLiked(itemID: currentItem.canonicalID)

            Button {
                stateStore.toggleLike(itemID: currentItem.canonicalID)
            } label: {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(isLiked ? theme.likeColor : theme.viewer.chromeColor)
                    .padding(10)
                    .background(theme.viewer.buttonBackgroundColor, in: Circle())
            }
        }
    }

    private func progress(for index: Int) -> Double {
        if index < viewModel.currentItemIndex {
            return 1
        }

        if index > viewModel.currentItemIndex {
            return 0
        }

        return currentProgress
    }

    private func tickProgress() {
        guard isCurrentImageReady else { return }

        let step = 0.05 / itemDuration
        currentProgress = min(currentProgress + step, 1)

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
        }
    }

    private func goPrevious() {
        if currentProgress > 0.2 {
            currentProgress = 0
            return
        }

        let shouldAnimateStoryTransition = viewModel.currentItemIndex == 0 && viewModel.currentStoryIndex > 0

        if shouldAnimateStoryTransition {
            prepareStoryTransition(direction: .backward)
        }

        viewModel.moveToPrevious()

        if shouldAnimateStoryTransition {
            startStoryTransition()
        }
    }

    private func goNextOrDismiss() {
        listViewModel.loadMoreIfNeeded(currentStory: currentStory)
        viewModel.updateStories(stories)

        let isLastItemInStory = viewModel.currentItemIndex == currentStory.items.count - 1
        let hasNextStory = viewModel.currentStoryIndex < stories.count - 1

        if isLastItemInStory && hasNextStory {
            prepareStoryTransition(direction: .forward)
        }

        if !viewModel.moveToNext() {
            dismiss()
            return
        }

        if isLastItemInStory && hasNextStory {
            startStoryTransition()
        }
    }

    private func prepareStoryTransition(direction: StoryTransitionDirection) {
        let width = max(viewerWidth, 1)

        storyTransitionDirection = direction
        outgoingPage = StoryPageSnapshot(item: currentItem)

        switch direction {
        case .forward:
            incomingPageAnchor = .leading
            incomingPageRotation = 88
            incomingPageOffset = width * 0.92
            outgoingPageAnchor = .trailing
            outgoingPageRotation = 0
            outgoingPageOffset = 0
        case .backward:
            incomingPageAnchor = .trailing
            incomingPageRotation = -88
            incomingPageOffset = -width * 0.92
            outgoingPageAnchor = .leading
            outgoingPageRotation = 0
            outgoingPageOffset = 0
        }
    }

    private func startStoryTransition() {
        let width = max(viewerWidth, 1)

        withAnimation(.easeInOut(duration: transitionDuration)) {
            incomingPageRotation = 0
            incomingPageOffset = 0

            switch storyTransitionDirection {
            case .forward:
                outgoingPageRotation = -88
                outgoingPageOffset = -width * 0.92
            case .backward:
                outgoingPageRotation = 88
                outgoingPageOffset = width * 0.92
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + transitionDuration) {
            outgoingPage = nil
            outgoingPageRotation = 0
            outgoingPageOffset = 0
            incomingPageRotation = 0
            incomingPageOffset = 0
        }
    }
}

// MARK: - Previews

private struct StoryViewerScreenPreviewContainer: View {
    @StateObject private var listViewModel = StoryListViewModel()

    var body: some View {
        Group {
            if let firstStory = listViewModel.stories.first {
                StoryViewerScreen(listViewModel: listViewModel, selectedStoryID: firstStory.id)
            } else {
                Color.black
                    .task {
                        listViewModel.loadInitialIfNeeded()
                    }
            }
        }
        .environmentObject(StoryStateStore())
        .environmentObject(ThemeStore())
    }
}

#Preview {
    StoryViewerScreenPreviewContainer()
}
