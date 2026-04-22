//
//  ThemeStore.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 21/04/2026.
//

import SwiftUI
import Combine

@MainActor
final class ThemeStore: ObservableObject {

    @Published private(set) var currentTheme: Theme {
        didSet {
            defaults.set(currentTheme.id, forKey: selectionKey)
        }
    }

    var themes: [Theme] {
        Theme.allThemes
    }

    var selectedThemeID: String {
        currentTheme.id
    }

    private let defaults: UserDefaults
    private let selectionKey = "theme.selection"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedValue = defaults.string(forKey: selectionKey) ?? Theme.rainbow.id
        self.currentTheme = Theme.make(for: storedValue)
    }

    func selectTheme(id: String) {
        currentTheme = Theme.make(for: id)
    }
}
