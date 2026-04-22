//
//  StoriesDemoApp.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 21/04/2026.
//

import SwiftUI

@main
struct StoriesDemoApp: App {
    @StateObject private var storyStateStore = StoryStateStore()
    @StateObject private var analyticsStore = StoryAnalyticsStore()
    @StateObject private var themeStore = ThemeStore()

    var body: some Scene {
        WindowGroup {
            if let preferredColorScheme = themeStore.currentTheme.preferredColorScheme {
                StoriesRootView()
                    .environmentObject(storyStateStore)
                    .environmentObject(analyticsStore)
                    .environmentObject(themeStore)
                    .colorScheme(preferredColorScheme)
            } else {
                StoriesRootView()
                    .environmentObject(storyStateStore)
                    .environmentObject(analyticsStore)
                    .environmentObject(themeStore)
            }
        }
    }
}
