//
//  StoryPageContent.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 21/04/2026.
//

import SwiftUI

struct StoryPageContent: View {

    let story: Story
    let item: StoryItem
    let safeAreaInsets: EdgeInsets
    let currentItemIndex: Int
    let currentProgress: Double
    let isLiked: Bool
    let theme: Theme
    let allowsInteraction: Bool
    let onImageReady: (Bool) -> Void
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onDismiss: () -> Void
    let onToggleLike: () -> Void
    let dismissKeyboardRequested: Binding<Bool>
    let isReplyFocused: Binding<Bool>
    let isHoldActive: Binding<Bool>

    @State private var replyText = ""
    @FocusState private var isReplyFieldFocused: Bool
    @State private var holdActivationWorkItem: DispatchWorkItem?

    private let holdActivationDelay: TimeInterval = 0.2
    private let holdMaximumDistance: CGFloat = 12
    private let overlaysFadeAnimation = Animation.easeInOut(duration: 0.15)

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                StoryImage(
                    item: item,
                    chromeColor: theme.viewer.chromeColor,
                    onImageReady: onImageReady
                )

                HStack(spacing: 0) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard allowsInteraction else { return }
                            onPrevious()
                        }

                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard allowsInteraction else { return }
                            onNext()
                        }
                }

                TopOverlay()
                    .padding(.horizontal, 12)
                    .padding(.top, safeAreaInsets.top)
                    .padding(.bottom, 32)
                    .background(TopBackgroundProtection())
                    .opacity(overlaysOpacity)
                    .frame(maxHeight: .infinity, alignment: .top)

                BottomOverlay()
                    .padding(.horizontal, 12)
                    .padding(.bottom, max(safeAreaInsets.bottom, 12))
                    .padding(.top, 24)
                    .background(BottomBackgroundProtection())
                    .opacity(overlaysOpacity)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .onLongPressGesture(
                minimumDuration: holdActivationDelay,
                maximumDistance: holdMaximumDistance,
                pressing: handleHoldPressingChanged,
                perform: { }
            )
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("storyReplyFocusRequested"))) { _ in
                guard allowsInteraction else { return }
                isReplyFieldFocused = true
            }
            .onChange(of: isReplyFieldFocused) { _, focused in
                isReplyFocused.wrappedValue = focused
            }
            .onChange(of: dismissKeyboardRequested.wrappedValue) { _, requested in
                if requested {
                    isReplyFieldFocused = false
                    dismissKeyboardRequested.wrappedValue = false
                }
            }
            .onDisappear {
                holdActivationWorkItem?.cancel()
                holdActivationWorkItem = nil
                if isHoldActive.wrappedValue {
                    isHoldActive.wrappedValue = false
                }
            }
        }
    }

    private var overlaysOpacity: Double {
        isHoldActive.wrappedValue ? 0 : 1
    }

    private func handleHoldPressingChanged(_ isPressing: Bool) {
        guard allowsInteraction else { return }

        if isPressing {
            holdActivationWorkItem?.cancel()

            let workItem = DispatchWorkItem {
                withAnimation(overlaysFadeAnimation) {
                    isHoldActive.wrappedValue = true
                }
            }

            holdActivationWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + holdActivationDelay, execute: workItem)
            return
        }

        holdActivationWorkItem?.cancel()
        holdActivationWorkItem = nil

        guard isHoldActive.wrappedValue else { return }
        withAnimation(overlaysFadeAnimation) {
            isHoldActive.wrappedValue = false
        }
    }

    // MARK: - Top Overlay
    private func TopOverlay() -> some View {
        VStack(spacing: 12) {
            ProgressBars()

            HStack {
                UserTag()
                Spacer()
                CloseButton()
            }
        }
    }

    private func UserTag() -> some View {
        HStack(spacing: 10) {
            StoryAvatarImage(url: story.user.avatarURL, chromeColor: theme.viewer.chromeColor)

            Text(story.user.username)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.viewer.chromeColor)
        }
    }

    private func CloseButton() -> some View {
        Button(action: onDismiss) {
            Image(systemName: "xmark")
                .font(.headline)
                .foregroundStyle(theme.viewer.chromeColor)
                .padding(10)
                .background(theme.viewer.badgeBackgroundColor, in: Circle())
        }
        .disabled(!allowsInteraction)
        .accessibilityLabel("Close story")
        .accessibilityHint("Dismisses the story viewer")
    }

    private func TopBackgroundProtection(color: Color = .black) -> some View {
        LinearGradient(colors: [color.opacity(0.4), color.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom)
    }

    // MARK: - Bottom Overlay
    private func BottomOverlay() -> some View {
        HStack {
            ReplyField()
            LikeButton()
        }
    }

    private func BottomBackgroundProtection(color: Color = .black) -> some View {
        LinearGradient(colors: [color.opacity(0.4), color.opacity(0.3), .clear], startPoint: .bottom, endPoint: .top)
    }


    // MARK: - Reply Field
    private func ReplyField() -> some View {
        TextField("Reply to story", text: $replyText)
            .textInputAutocapitalization(.sentences)
            .submitLabel(.send)
            .focused($isReplyFieldFocused)
            .onSubmit {
                submitReply()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.systemBackground).opacity(0.5), in: Capsule())
            .foregroundStyle(.primary)
            .disabled(!allowsInteraction)
            .accessibilityLabel("Reply field")
            .accessibilityHint("Type a reply to the current story")
    }

    private func submitReply() {
        guard !replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        replyText = ""
        isReplyFieldFocused = false
    }

    // MARK: - Like Button
    private func LikeButton() -> some View {
        Button(action: onToggleLike) {
            Image(systemName: isLiked ? "heart.fill" : "heart")
                .font(.title2)
                .foregroundStyle(isLiked ? theme.likeColor : theme.viewer.chromeColor)
                .padding(12)
                .background(theme.viewer.buttonBackgroundColor, in: Circle())
        }
        .disabled(!allowsInteraction)
        .accessibilityLabel(isLiked ? "Unlike story" : "Like story")
        .accessibilityHint("Toggles like for the current story")
    }

    // MARK: - Progress
    private func ProgressBars() -> some View {
        HStack(spacing: 4) {
            ForEach(Array(story.items.enumerated()), id: \.offset) { index, _ in
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(theme.viewer.progressTrackColor)

                        Capsule()
                            .fill(theme.viewer.progressFillColor)
                            .frame(width: proxy.size.width * progress(for: index))
                    }
                }
                .frame(height: 3)
            }
        }
    }

    private func progress(for index: Int) -> Double {
        if index < currentItemIndex {
            return 1
        }

        if index > currentItemIndex {
            return 0
        }

        return currentProgress
    }
}

// MARK: Preview
#Preview {
    StoryPreviewContainer(withDependencies: { listViewModel, story, _, _ in
        StoryViewerView(listViewModel: listViewModel, selectedStoryID: story.id)
    })
}
