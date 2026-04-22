//
//  Theme+Samples.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 21/04/2026.
//

extension Theme {

    static let allThemes: [Theme] = [.rainbow, .dualCamera, .ghost, .chatter, .channel]

    static func make(for id: String) -> Theme {
        allThemes.first(where: { $0.id == id }) ?? Theme()
    }
}