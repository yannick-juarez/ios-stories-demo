//
//  StoryImageDownloadCoordinator.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 22/04/2026.
//

import Foundation

actor StoryImageDownloadCoordinator {
    
    private var tasks: [URL: Task<Data, Error>] = [:]

    func data(for url: URL) async throws -> Data {
        if let existingTask = tasks[url] {
            return try await existingTask.value
        }

        let task = Task<Data, Error> {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        }

        tasks[url] = task
        defer {
            tasks[url] = nil
        }

        return try await task.value
    }
}
