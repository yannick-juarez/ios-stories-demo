//
//  StoryBubbleView.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 21/04/2026.
//

import SwiftUI

struct StoryBubbleView: View {
    let story: Story
    let isSeen: Bool
    let hasLike: Bool

    @EnvironmentObject private var themeStore: ThemeStore

    private var theme: Theme { themeStore.currentTheme }

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                StoryAvatarView(url: story.user.avatarURL, isSeen: isSeen)

                if hasLike {
                    Image(systemName: "heart.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(theme.likeIconColor)
                        .padding(6)
                        .background(theme.likeColor, in: Circle())
                        .offset(x: 4, y: 2)
                }
            }

            VStack(spacing: 2) {
                Text(story.user.username)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.text.primaryColor)
                    .lineLimit(1)
                    .frame(width: theme.avatar.frameSize)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(story.user.username)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint("Opens this story")
    }

    private var accessibilityValue: String {
        let seenValue = isSeen ? "Seen" : "Unseen"
        let likeValue = hasLike ? "Contains liked content" : "No liked content"
        return "\(seenValue), \(likeValue)"
    }
}
