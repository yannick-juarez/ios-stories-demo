import SwiftUI

struct StoryListScreen: View {
    @StateObject private var viewModel = StoryListViewModel()
    @EnvironmentObject private var stateStore: StoryStateStore
    @EnvironmentObject private var themeStore: ThemeStore

    @State private var selectedStory: Story?

    private var theme: Theme {
        themeStore.currentTheme
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 18) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 14) {
                            ForEach(viewModel.stories) { story in
                                StoryBubbleView(
                                    story: story,
                                    isSeen: stateStore.isSeen(storyID: story.canonicalID),
                                    hasLike: stateStore.storyHasLikedItems(story),
                                    theme: theme
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedStory = story
                                }
                                .onAppear {
                                    viewModel.loadMoreIfNeeded(currentStory: story)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .scrollClipDisabled()
                }
                .background(theme.surfaces.railBackgroundColor)

                StoryListDemoControls()

                Divider()

                Spacer()
            }
            .background(theme.surfaces.canvasColor.ignoresSafeArea())
            .navigationTitle("Stories")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                viewModel.loadInitialIfNeeded()
            }
            .fullScreenCover(item: $selectedStory) { story in
                StoryViewerScreen(listViewModel: viewModel, selectedStoryID: story.id)
                    .environmentObject(stateStore)
                    .environmentObject(themeStore)
            }
        }
    }


    // MARK: - Demo Controls
    @ViewBuilder
    private func StoryListDemoControls() -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading) {
                Text("Theme")
                    .font(.subheadline.bold())
                Picker(
                    "Theme",
                    selection: Binding(
                        get: { themeStore.selectedThemeID },
                        set: { themeStore.selectTheme(id: $0) }
                    )
                ) {
                    ForEach(themeStore.themes) { theme in
                        Text(theme.title)
                            .tag(theme.id)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading) {
                Text("Debug")
                    .font(.subheadline.bold())
                Button("Reset") {
                    stateStore.resetAll()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

#Preview {
    StoryListScreen()
        .environmentObject(StoryStateStore())
        .environmentObject(ThemeStore())
}
