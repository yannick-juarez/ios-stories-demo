//
//  StoryImageLoader+Helpers.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 22/04/2026.
//

import SwiftUI
import ImageIO

extension StoryImageLoader {

    // MARK: - Cache

    nonisolated static func cachedImage(
        for url: URL,
        targetSize: CGSize?,
        scale: CGFloat
    ) -> UIImage? {
        guard let cachedImage = imageFromCache(for: url) else {
            return nil
        }

        return isCachedImage(cachedImage, sufficientFor: targetSize, scale: scale) ? cachedImage : nil
    }

    nonisolated static func imageFromCache(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    nonisolated static func storeInCache(_ image: UIImage, for url: URL) {
        if let cachedImage = imageFromCache(for: url),
           pixelDimension(of: cachedImage) > pixelDimension(of: image) {
            return
        }

        cache.setObject(image, forKey: url as NSURL, cost: imageCost(for: image))
    }

    nonisolated static func downsample(
        data: Data,
        to pointSize: CGSize,
        scale: CGFloat
    ) -> UIImage? {
        let maxDimensionInPixels = max(pointSize.width, pointSize.height) * max(scale, 1)
        guard maxDimensionInPixels > 0 else { return UIImage(data: data) }

        let sourceOptions: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]

        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions as CFDictionary) else {
            return UIImage(data: data)
        }

        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(maxDimensionInPixels)
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions as CFDictionary) else {
            return UIImage(data: data)
        }

        return UIImage(cgImage: cgImage)
    }

    nonisolated static func imageCost(for image: UIImage) -> Int {
        let width = Int(image.size.width * image.scale)
        let height = Int(image.size.height * image.scale)
        return max(width * height * 4, 1)
    }

    nonisolated static func isCachedImage(
        _ image: UIImage,
        sufficientFor targetSize: CGSize?,
        scale: CGFloat
    ) -> Bool {
        guard let targetSize, targetSize.width > 0, targetSize.height > 0 else {
            return true
        }

        // Keep a tolerance margin so tiny layout differences don't force unnecessary re-downloads.
        let requiredPixels = max(targetSize.width, targetSize.height) * max(scale, 1) * 0.9
        return pixelDimension(of: image) >= requiredPixels
    }

    nonisolated static func pixelDimension(of image: UIImage) -> CGFloat {
        max(image.size.width * image.scale, image.size.height * image.scale)
    }

    static func tuneCacheLimits(queueSize: Int, targetSize: CGSize, displayScale: CGFloat) {
        let normalizedQueueSize = max(queueSize, 0)
        let pixelWidth = Int(max(targetSize.width * displayScale, 1))
        let pixelHeight = Int(max(targetSize.height * displayScale, 1))
        let estimatedImageCost = max(pixelWidth * pixelHeight * 4, 1)

        // Keep enough room for prefetched images plus current/previous pages.
        let desiredImageSlots = max(normalizedQueueSize + 4, 8)
        let desiredTotalCost = estimatedImageCost * desiredImageSlots

        let minBudget = 96 * 1024 * 1024
        let maxBudget = 512 * 1024 * 1024
        let boundedBudget = Swift.max(minBudget, Swift.min(maxBudget, desiredTotalCost))

        cache.totalCostLimit = boundedBudget
        cache.countLimit = Swift.max(320, desiredImageSlots * 3)
    }
}
