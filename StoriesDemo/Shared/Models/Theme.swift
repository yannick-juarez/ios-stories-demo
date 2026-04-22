//
//  Theme.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 21/04/2026.
//

import Foundation
import SwiftUI

struct Theme: Identifiable {
    
    struct Surfaces {
        var canvasColor: Color = Color(.systemBackground)
        var secondaryCanvasColor: Color = Color(.secondarySystemBackground)
    }

    struct Text {
        var primaryColor: Color = .primary
        var secondaryColor: Color = .secondary
        var unseenColor: Color = Color(red: 0.93, green: 0.21, blue: 0.39)
    }

    struct Avatar {
        var imageSize: CGFloat = 68
        var ringWidth: CGFloat = 3
        var ringSpacing: CGFloat = 3
        var seenRingColor: Color = Color.gray.opacity(0.45)
        var unseenRingGradient: LinearGradient = LinearGradient(
            colors: [
                Color(red: 0.99, green: 0.72, blue: 0.24),
                Color(red: 0.98, green: 0.36, blue: 0.33),
                Color(red: 0.88, green: 0.18, blue: 0.52),
                Color(red: 0.45, green: 0.21, blue: 0.85)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        var imageCornerRadiusRatio: CGFloat = 0.5
        var ringCornerRadiusRatio: CGFloat = 0.5

        var frameSize: CGFloat {
            imageSize + (ringSpacing * 2) + ringWidth
        }
    }

    struct Viewer {
        var backgroundColor: Color = .black
        var chromeColor: Color = .white
        var badgeBackgroundColor: Color = Color(.systemBackground).opacity(0.4)
        var buttonBackgroundColor: Color = Color(.systemBackground).opacity(0.3)
        var progressTrackColor: Color = .white.opacity(0.35)
        var progressFillColor: Color = .white
        var transition: StoryTransition = .linear
    }

    struct List {
        var bubbleSpacing: CGFloat = 14
        var horizontalPadding: CGFloat = 16
        var verticalPadding: CGFloat = 12
    }

    var id: String = UUID().uuidString
    var title: String = "Sample"
    var surfaces: Surfaces = Surfaces()
    var text: Text = Text()
    var avatar: Avatar = Avatar()
    var list: List = List()
    var viewer: Viewer = Viewer()
    var likeColor: Color = .pink
    var likeIconColor: Color = .white
    var preferredColorScheme: ColorScheme? = nil
}
