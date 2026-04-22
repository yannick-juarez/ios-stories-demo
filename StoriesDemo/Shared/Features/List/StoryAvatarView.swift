//
//  StoryAvatarView.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 21/04/2026.
//

import SwiftUI

struct StoryAvatarView: View {

    let url: URL
    let isSeen: Bool

    @EnvironmentObject private var themeStore: ThemeStore
    @StateObject private var loader = StoryImageLoader()

    private var theme: Theme { themeStore.currentTheme }

    private var imageSize: CGFloat {
        theme.avatar.imageSize
    }

    private var frameSize: CGFloat {
        theme.avatar.frameSize
    }

    private var imageCornerRadius: CGFloat {
        imageSize * theme.avatar.imageCornerRadiusRatio
    }

    private var ringCornerRadius: CGFloat {
        frameSize * theme.avatar.ringCornerRadiusRatio
    }

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: imageSize, height: imageSize)
                    .cornerRadius(imageCornerRadius)
            } else if loader.didFail {
                RoundedRectangle(cornerRadius: imageCornerRadius, style: .continuous)
                    .fill(.gray.opacity(0.3))
                    .frame(width: imageSize, height: imageSize)
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundStyle(theme.text.secondaryColor)
                    }
            } else {
                ProgressView()
                    .frame(width: imageSize, height: imageSize)
            }
        }
        .overlay {
            if isSeen {
                RoundedRectangle(cornerRadius: ringCornerRadius, style: .continuous)
                    .stroke(theme.avatar.seenRingColor, lineWidth: theme.avatar.ringWidth)
                    .frame(width: frameSize, height: frameSize)
            } else {
                RoundedRectangle(cornerRadius: ringCornerRadius, style: .continuous)
                    .stroke(theme.avatar.unseenRingGradient, lineWidth: theme.avatar.ringWidth)
                    .frame(width: frameSize, height: frameSize)
            }
        }
        .frame(width: frameSize, height: frameSize)
        .task(id: url) {
            loader.load(from: url, targetSize: CGSize(width: imageSize, height: imageSize))
        }
    }
}
