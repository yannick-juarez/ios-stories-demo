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
    let theme: Theme

    private var imageSize: CGFloat {
        theme.avatar.imageSize
    }

    private var frameSize: CGFloat {
        theme.avatar.frameSize
    }

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(width: imageSize, height: imageSize)
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: imageSize, height: imageSize)
                    .clipShape(Circle())
            case .failure:
                Circle()
                    .fill(.gray.opacity(0.3))
                    .frame(width: imageSize, height: imageSize)
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundStyle(theme.text.secondaryColor)
                    }
            @unknown default:
                EmptyView()
            }
        }
        .overlay {
            if isSeen {
                Circle()
                    .strokeBorder(theme.avatar.seenRingColor, lineWidth: theme.avatar.ringWidth)
                    .frame(width: frameSize, height: frameSize)
            } else {
                Circle()
                    .strokeBorder(theme.avatar.unseenRingGradient, lineWidth: theme.avatar.ringWidth)
                    .frame(width: frameSize, height: frameSize)
            }
        }
        .frame(width: frameSize, height: frameSize)
    }
}
