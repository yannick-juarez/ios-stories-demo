//
//  StoriesRootView.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 21/04/2026.
//

import SwiftUI

struct StoriesRootView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    var body: some View {
        StoryListScreen()
            .background(themeStore.currentTheme.surfaces.canvasColor.ignoresSafeArea())
    }
}

#Preview {
    StoriesRootView()
        .environmentObject(StoryStateStore())
        .environmentObject(ThemeStore())
}
