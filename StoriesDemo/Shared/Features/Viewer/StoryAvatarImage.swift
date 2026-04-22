//
//  StoryAvatarImage.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 21/04/2026.
//

import SwiftUI

struct StoryAvatarImage: View {

    let url: URL
    let chromeColor: Color
    var radius: CGFloat = 34

    @StateObject private var loader = StoryImageLoader()

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: self.radius, height: self.radius)
                    .clipShape(Circle())
            } else if loader.didFail {
                Circle()
                    .fill(chromeColor.opacity(0.2))
                    .frame(width: self.radius, height: self.radius)
            } else {
                Circle()
                    .fill(chromeColor.opacity(0.2))
                    .frame(width: self.radius, height: self.radius)
                    .overlay {
                        ProgressView()
                            .tint(chromeColor)
                            .scaleEffect(0.7)
                    }
            }
        }
        .task(id: url) {
            loader.load(from: url, targetSize: CGSize(width: 34, height: 34))
        }
    }
}
