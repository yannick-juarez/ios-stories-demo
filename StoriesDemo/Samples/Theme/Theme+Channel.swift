//
//  Theme+Channel.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 21/04/2026.
//

import SwiftUI

extension Theme {

    static let channel = Theme(
        id: "channel",
        title: "Channel",
        surfaces: Surfaces(
            canvasColor: Color(red: 0.31, green: 0.18, blue: 0.44),
            secondaryCanvasColor: Color(red: 0.24, green: 0.14, blue: 0.36)
        ),
        text: Text(
            primaryColor: .white,
            secondaryColor: Color.white.opacity(0.78),
            unseenColor: .white
        ),
        avatar: Avatar(
            imageSize: 72,
            ringWidth: 3,
            ringSpacing: 2,
            seenRingColor: Color.white.opacity(0.65),
            unseenRingGradient: LinearGradient(
                colors: [
                    Color.white,
                    Color.white.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            imageCornerRadiusRatio: 0.2,
            ringCornerRadiusRatio: 0.2
        ),
        viewer: Viewer(
            backgroundColor: Color(red: 0.11, green: 0.07, blue: 0.19),
            chromeColor: .white,
            badgeBackgroundColor: Color.white.opacity(0.16),
            buttonBackgroundColor: Color.white.opacity(0.14),
            progressTrackColor: Color.white.opacity(0.24),
            progressFillColor: .white,
            transition: .fade
        ),
        likeColor: .white,
        likeIconColor: Color(red: 0.31, green: 0.18, blue: 0.44),
        preferredColorScheme: .dark
    )
}
