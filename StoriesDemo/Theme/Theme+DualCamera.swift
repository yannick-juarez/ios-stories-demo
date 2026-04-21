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
        tintColor: .white,
        surfaces: Surfaces(
            railBackgroundColor: Color(white: 0.04),
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
            frameSize: 74,
            ringWidth: 3,
            seenRingColor: Color(white: 0.4),
            unseenRingGradient: LinearGradient(
                colors: [Color.white, Color(white: 0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ),
        viewer: Viewer(
            backgroundColor: .black,
            chromeColor: .white,
            badgeBackgroundColor: .white.opacity(0.12),
            buttonBackgroundColor: .white.opacity(0.12),
            progressTrackColor: .white.opacity(0.2),
            progressFillColor: .white
        ),
        likeColor: .white,
        preferredColorScheme: .dark
    )

}
