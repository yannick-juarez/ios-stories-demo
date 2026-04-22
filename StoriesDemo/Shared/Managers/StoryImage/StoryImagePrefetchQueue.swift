//
//  StoryImagePrefetchQueue.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 22/04/2026.
//

import Foundation
import SwiftUI

actor StoryImagePrefetchQueue {

    private var queue: [URL] = []
    private var tasks: [URL: Task<Void, Never>] = [:]
    private var pendingQueue: [URL] = []
    private var targetSize: CGSize = .zero
    private var displayScale: CGFloat = 1
    private var maxConcurrentTasks = 2

    func update(targetURLs: [URL], queueSize: Int, targetSize: CGSize, displayScale: CGFloat) {
        let size = max(queueSize, 0)
        queue = Self.uniqueURLs(from: targetURLs, limit: size)
        self.targetSize = targetSize
        self.displayScale = displayScale
        maxConcurrentTasks = min(max(size, 1), 4)

        pendingQueue = queue.filter { url in
            guard tasks[url] == nil else { return false }
            return !shouldSkipPrefetch(for: url)
        }

        schedulePrefetchIfNeeded()
    }

    private func taskDidComplete(for url: URL) {
        tasks.removeValue(forKey: url)
        schedulePrefetchIfNeeded()
    }

    private func schedulePrefetchIfNeeded() {
        while tasks.count < maxConcurrentTasks, let nextURL = dequeueNextPendingURL() {
            startPrefetch(for: nextURL)
        }
    }

    private func dequeueNextPendingURL() -> URL? {
        while !pendingQueue.isEmpty {
            let url = pendingQueue.removeFirst()

            if tasks[url] != nil {
                continue
            }

            if shouldSkipPrefetch(for: url) {
                continue
            }
            return url
        }
        return nil
    }

    private func shouldSkipPrefetch(for url: URL) -> Bool {
        if let cachedImage = StoryImageLoader.imageFromCache(for: url),
           StoryImageLoader.isCachedImage(cachedImage, sufficientFor: targetSize, scale: displayScale) {
            return true
        }

        return false
    }

    private func startPrefetch(for url: URL) {
        let targetSize = self.targetSize
        let displayScale = self.displayScale

        tasks[url] = Task {
            do {
                let data = try await StoryImageLoader.downloadCoordinator.data(for: url)
                let image = StoryImageLoader.downsample(
                    data: data,
                    to: targetSize,
                    scale: displayScale
                )

                guard !Task.isCancelled, let image else {
                    self.taskDidComplete(for: url)
                    return
                }

                StoryImageLoader.storeInCache(image, for: url)
            } catch {
                print("[ImagePrefetch] Prefetch failed: \(url.lastPathComponent) - \(error)")
            }

            self.taskDidComplete(for: url)
        }
    }

    private static func uniqueURLs(from urls: [URL], limit: Int) -> [URL] {
        guard limit > 0 else { return [] }

        var seen = Set<URL>()
        var unique: [URL] = []
        unique.reserveCapacity(limit)

        for url in urls where !seen.contains(url) {
            seen.insert(url)
            unique.append(url)

            if unique.count == limit {
                break
            }
        }

        return unique
    }
}
