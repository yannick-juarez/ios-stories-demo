//
//  Theme+Ghost.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 21/04/2026.
//

import SwiftUI

extension Theme {

    static let ghost = Theme(
        id: "ghost",
        title: "Ghost",
        surfaces: Surfaces(
            canvasColor: .white,
            secondaryCanvasColor: Color(red: 0.98, green: 0.94, blue: 0.43)
        ),
        text: Text(
            primaryColor: .black,
            secondaryColor: Color.black.opacity(0.65),
            unseenColor: Color(red: 0.44, green: 0.22, blue: 0.88)
        ),
        avatar: Avatar(
            imageSize: 78,
            ringWidth: 3,
            ringSpacing: 3,
            seenRingColor: Color(red: 0.56, green: 0.52, blue: 0.64),
            unseenRingGradient: LinearGradient(
                colors: [
                    Color(red: 0.59, green: 0.36, blue: 0.99),
                    Color(red: 0.44, green: 0.22, blue: 0.88)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ),
        viewer: Viewer(
            backgroundColor:.white,
            chromeColor: .white,
            badgeBackgroundColor: Color.white.opacity(0.14),
            buttonBackgroundColor: Color.black.opacity(0.24),
            progressTrackColor: Color.white.opacity(0.28),
            progressFillColor: .white,
            transition: .linear
        ),
        likeColor: Color(red: 0.59, green: 0.36, blue: 0.99),
        likeIconColor: .white,
        preferredColorScheme: .light
    )
}
