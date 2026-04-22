//
//  StoriesRootView.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 21/04/2026.
//

import SwiftUI

struct StoriesRootView: View {

    private struct ThemeAnalyticsRow: Identifiable {
        let id: String
        let title: String
        let views: Int
        let likes: Int
    }

    @EnvironmentObject private var stateStore: StoryStateStore
    @EnvironmentObject private var analyticsStore: StoryAnalyticsStore
    @EnvironmentObject private var themeStore: ThemeStore

    @State private var isDebugPresented: Bool = false

    private var theme: Theme {
        themeStore.currentTheme
    }

    private var analyticsRows: [ThemeAnalyticsRow] {
        themeStore.themes.map { theme in
            let analytics = analyticsStore.analytics(forThemeID: theme.id)
            return ThemeAnalyticsRow(
                id: theme.id,
                title: theme.title,
                views: analytics.views,
                likes: analytics.likes
            )
        }
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                StoryListView()
            }
            .background(theme.surfaces.canvasColor.ignoresSafeArea())
            .refreshable {
                stateStore.resetAll()
                analyticsStore.resetAll()
            }
            .navigationTitle("Stories")
            .navigationSubtitle("Pull to reset")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: self.$isDebugPresented) {
                NavigationStack {
                    List {
                        ThemeSection()
                        AnalyticsSection()
                    }
                    .navigationTitle("Debug")
                }
            }
            .onShake {
                self.isDebugPresented = true
            }
        }
    }

    // MARK: - Theme Section
    private func ThemeSection() -> some View {
        Section(header: Text("Theme")) {
            Picker("Theme", selection: Binding(
                    get: { themeStore.selectedThemeID },
                    set: { themeStore.selectTheme(id: $0) }
                )
            ) {
                ForEach(themeStore.themes) { theme in
                    Text(theme.title)
                        .tag(theme.id)
                }
            }
            .pickerStyle(.navigationLink)
        }
    }

    // MARK: - Analytics Section
    private func AnalyticsSection() -> some View {
        Section(header: Text("A/B Test Analytics")) {
            ForEach(analyticsRows) { row in
                HStack {
                    Text(row.title)

                    Spacer()

                    Label("\(row.views)", systemImage: "eye")
                        .font(.caption.monospacedDigit())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.thinMaterial, in: Capsule())

                    Label("\(row.likes)", systemImage: "heart")
                        .font(.caption.monospacedDigit())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.thinMaterial, in: Capsule())
                }
            }
        }
    }
}

// MARK: - Previews

#Preview {
    StoriesRootView()
        .environmentObject(StoryStateStore())
        .environmentObject(StoryAnalyticsStore())
        .environmentObject(ThemeStore())
}
