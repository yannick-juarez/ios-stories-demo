//
//  Theme+DualCamera.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 21/04/2026.
//

import SwiftUI

extension Theme {

    static let dualCamera = Theme(
        id: "timeSensitive",
        title: "Dual Camera",
        surfaces: Surfaces(
            canvasColor: .black,
            secondaryCanvasColor: Color(white: 0.1)
        ),
        text: Text(
            primaryColor: .white,
            secondaryColor: Color(white: 0.7),
            unseenColor: .white
        ),
        avatar: Avatar(
            imageSize: 68,
            ringWidth: 3,
            ringSpacing: 0,
            seenRingColor: Color(white: 0.45),
            unseenRingGradient: LinearGradient(
                colors: [Color.white, Color(white: 0.82)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            imageCornerRadiusRatio: 0.22,
            ringCornerRadiusRatio: 0.22
        ),
        viewer: Viewer(
            backgroundColor: .black,
            chromeColor: .white,
            badgeBackgroundColor: .black.opacity(0.4),
            buttonBackgroundColor: .black.opacity(0.4),
            progressTrackColor: .white.opacity(0.2),
            progressFillColor: .white,
            transition: .linear
        ),
        likeColor: .white,
        likeIconColor: .black,
        preferredColorScheme: .dark
    )

}
