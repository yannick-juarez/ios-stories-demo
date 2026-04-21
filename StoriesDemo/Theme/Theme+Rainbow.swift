//
//  Theme+Rainbow.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 21/04/2026.
//

import SwiftUI

extension Theme {

    static let rainbow = Theme(
        id: "rainbow",
        title: "Rainbow",
        tintColor: Color(red: 0.98, green: 0.32, blue: 0.45),
        surfaces: Surfaces(
            railBackgroundColor: Color(red: 1.0, green: 0.98, blue: 0.96),
            canvasColor: Color(.systemBackground),
            secondaryCanvasColor: Color(.secondarySystemBackground)
        ),
        text: Text(
            primaryColor: .primary,
            secondaryColor: .secondary,
            unseenColor: Color(red: 0.93, green: 0.21, blue: 0.39)
        ),
        avatar: Avatar(
            imageSize: 68,
            frameSize: 74,
            ringWidth: 3,
            seenRingColor: Color.gray.opacity(0.45),
            unseenRingGradient: LinearGradient(
                colors: [
                    Color(red: 0.99, green: 0.72, blue: 0.24),
                    Color(red: 0.98, green: 0.36, blue: 0.33),
                    Color(red: 0.88, green: 0.18, blue: 0.52),
                    Color(red: 0.45, green: 0.21, blue: 0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ),
        viewer: Viewer(
            backgroundColor: .black,
            chromeColor: .white,
            badgeBackgroundColor: .white.opacity(0.18),
            buttonBackgroundColor: .black.opacity(0.25),
            progressTrackColor: .white.opacity(0.35),
            progressFillColor: .white
        ),
        likeColor: Color(red: 0.99, green: 0.29, blue: 0.56),
        preferredColorScheme: nil
    )
}
