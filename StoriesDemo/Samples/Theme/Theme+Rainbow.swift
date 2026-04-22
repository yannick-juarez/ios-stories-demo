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
        surfaces: Surfaces(
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
            ringWidth: 3,
            ringSpacing: 3,
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
            badgeBackgroundColor: Color(.systemBackground).opacity(0.4),
            buttonBackgroundColor: Color(.systemBackground).opacity(0.4),
            progressTrackColor: .white.opacity(0.35),
            progressFillColor: .white,
            transition: .cube
        ),
        likeColor: Color(red: 0.99, green: 0.29, blue: 0.56),
        likeIconColor: .white,
        preferredColorScheme: nil
    )
}
