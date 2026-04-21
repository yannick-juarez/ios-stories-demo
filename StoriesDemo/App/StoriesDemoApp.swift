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
    @StateObject private var themeStore = ThemeStore()

    var body: some Scene {
        WindowGroup {
            StoriesRootView()
                .environmentObject(storyStateStore)
                .environmentObject(themeStore)
                .tint(themeStore.currentTheme.tintColor)
                .preferredColorScheme(themeStore.currentTheme.preferredColorScheme)
        }
    }
}
