//
//  Theme+Chatter.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 21/04/2026.
//

import SwiftUI

extension Theme {

    static let chatter = Theme(
        id: "chatter",
        title: "Chat",
        surfaces: Surfaces(
            canvasColor: Color(red: 0.92, green: 0.98, blue: 0.93),
            secondaryCanvasColor: Color(red: 0.84, green: 0.95, blue: 0.86)
        ),
        text: Text(
            primaryColor: Color(red: 0.08, green: 0.14, blue: 0.1),
            secondaryColor: Color(red: 0.13, green: 0.24, blue: 0.16).opacity(0.75),
            unseenColor: Color(red: 0.0, green: 0.66, blue: 0.42)
        ),
        avatar: Avatar(
            imageSize: 68,
            ringWidth: 3,
            ringSpacing: 2,
            seenRingColor: Color(red: 0.55, green: 0.67, blue: 0.58),
            unseenRingGradient: LinearGradient(
                colors: [
                    Color(red: 0.0, green: 0.76, blue: 0.49),
                    Color(red: 0.0, green: 0.56, blue: 0.36)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ),
        viewer: Viewer(
            backgroundColor: Color(red: 0.03, green: 0.14, blue: 0.11),
            chromeColor: .white,
            badgeBackgroundColor: Color.white.opacity(0.16),
            buttonBackgroundColor: Color.black.opacity(0.22),
            progressTrackColor: Color.white.opacity(0.24),
            progressFillColor: Color(red: 0.0, green: 0.82, blue: 0.53),
            transition: .linear
        ),
        likeColor: Color(red: 0.0, green: 0.82, blue: 0.53),
        likeIconColor: .white,
        preferredColorScheme: nil
    )
}
