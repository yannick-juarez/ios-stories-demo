//
//  StoryImage.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 21/04/2026.
//

import SwiftUI

struct StoryImage: View {
    let item: StoryItem
    let chromeColor: Color
    let onImageReady: (Bool) -> Void

    @StateObject private var loader = StoryImageLoader()
    @Environment(\.displayScale) private var displayScale
    @State private var containerSize: CGSize = .zero
    @State private var cachedImage: UIImage?

    private var loadRequestID: String {
        let width = Int(containerSize.width.rounded())
        let height = Int(containerSize.height.rounded())
        return "\(item.imageURL.absoluteString)-\(width)x\(height)"
    }

    var body: some View {
        let displayedImage = loader.image ?? cachedImage

        Group {
            if let image = displayedImage {
                GeometryReader { proxy in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                }
            } else if loader.didFail {
                Color.gray.opacity(0.45)
                    .overlay {
                        VStack(spacing: 10) {
                            Image(systemName: "wifi.exclamationmark")
                                .font(.largeTitle)
                                .foregroundStyle(chromeColor)

                            Text("Tap to retry")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(chromeColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        retryLoad()
                    }
            } else {
                ProgressView()
                    .tint(chromeColor)
                    .scaleEffect(1.2)
            }
        }
        .background {
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        containerSize = geo.size
                        updateCacheSnapshot(for: geo.size)
                    }
                    .onChange(of: geo.size) { _, newSize in
                        containerSize = newSize
                        updateCacheSnapshot(for: newSize)
                    }
            }
        }
        .onAppear {
            updateCacheSnapshot(for: containerSize)
            onImageReady(displayedImage != nil || loader.didFail)
        }
        .onChange(of: loadRequestID) { _, _ in
            updateCacheSnapshot(for: containerSize)
            onImageReady((loader.image ?? cachedImage) != nil || loader.didFail)
        }
        .onChange(of: loader.isLoading) { _, _ in
            onImageReady((loader.image ?? cachedImage) != nil || loader.didFail)
        }
        .onChange(of: loader.didFail) { _, _ in
            onImageReady((loader.image ?? cachedImage) != nil || loader.didFail)
        }
        .task(id: loadRequestID) {
            retryLoad()
        }
    }

    private func retryLoad() {
        updateCacheSnapshot(for: containerSize)

        guard containerSize.width > 0, containerSize.height > 0 else {
            // Avoid a full-resolution network fetch before layout has a real size.
            return
        }

        loader.load(
            from: item.imageURL,
            targetSize: containerSize,
            scale: displayScale
        )
    }

    private func updateCacheSnapshot(for size: CGSize) {
        let targetSize = size.width > 0 ? size : nil
        cachedImage = StoryImageLoader.cachedImage(
            for: item.imageURL,
            targetSize: targetSize,
            scale: displayScale
        )
    }
}
