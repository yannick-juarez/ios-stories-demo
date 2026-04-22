//
//  StoryImageLoader.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 21/04/2026.
//

import SwiftUI
import Combine

// MARK: - Story Image Loader
@MainActor
final class StoryImageLoader: ObservableObject {

    @Published private(set) var image: UIImage?
    @Published private(set) var isLoading = false
    @Published private(set) var didFail = false

    nonisolated(unsafe) static let cache: NSCache<NSURL, UIImage> = {
        let cache = NSCache<NSURL, UIImage>()
        cache.countLimit = 320
        cache.totalCostLimit = 192 * 1024 * 1024
        return cache
    }()
    static let downloadCoordinator = StoryImageDownloadCoordinator()
    private static let prefetchQueue = StoryImagePrefetchQueue()

    private var currentURL: URL?
    private var task: Task<Void, Never>?

    deinit {
        task?.cancel()
    }

    // MARK: Fetch
    func load(from url: URL, targetSize: CGSize? = nil, scale: CGFloat = 2.0) {
        if currentURL != url {
            task?.cancel()
            currentURL = url
            didFail = false
            isLoading = false

            if let cachedImage = Self.cachedImage(for: url, targetSize: targetSize, scale: scale) {
                image = cachedImage
                return
            }

            image = nil
        }

        if let currentImage = image, !isLoading, Self.isCachedImage(currentImage, sufficientFor: targetSize, scale: scale) {
            return
        }

        if isLoading {
            return
        }

        if let cachedImage = Self.imageFromCache(for: url) {
            if Self.isCachedImage(cachedImage, sufficientFor: targetSize, scale: scale) {
                image = cachedImage
                isLoading = false
                return
            } else {
                image = cachedImage
            }
        }

        isLoading = true
        task?.cancel()

        task = Task {
            do {
                let data = try await Self.downloadCoordinator.data(for: url)

                let downloadedImage: UIImage?
                if let targetSize {
                    downloadedImage = Self.downsample(data: data, to: targetSize, scale: scale)
                } else {
                    downloadedImage = UIImage(data: data)
                }

                guard !Task.isCancelled, let downloadedImage else {
                    return
                }

                Self.storeInCache(downloadedImage, for: url)
                image = downloadedImage
                isLoading = false
            } catch {
                guard !Task.isCancelled else { return }
                didFail = true
                isLoading = false
            }
        }
    }

    static func updatePrefetchQueue(
        with urls: [URL],
        queueSize: Int = 3,
        targetSize: CGSize,
        displayScale: CGFloat
    ) {
        tuneCacheLimits(queueSize: queueSize, targetSize: targetSize, displayScale: displayScale)

        Task {
            await prefetchQueue.update(
                targetURLs: urls,
                queueSize: queueSize,
                targetSize: targetSize,
                displayScale: displayScale
            )
        }
    }
}
