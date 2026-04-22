//
//  StoryTransition+Fade.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 21/04/2026.
//

import SwiftUI

extension StoryTransition {

    static var fade: StoryTransition {
        fade()
    }

    static func fade(duration: Double = 0.24) -> StoryTransition {
        StoryTransition(
            duration: duration,
            animation: .easeInOut(duration: duration),
            makePreparedStates: { _ in
                LayerStates(
                    incoming: fadePageState(opacity: 0),
                    outgoing: PageState.identity()
                )
            },
            makeFinalStates: { _ in
                LayerStates(
                    incoming: PageState.identity(),
                    outgoing: fadePageState(opacity: 0)
                )
            }
        )
    }

    private static func fadePageState(opacity: Double) -> PageState {
        PageState(
            translationX: 0,
            opacity: opacity,
            rotationY: 0,
            rotationAnchor: .center,
            perspective: 0.72,
            scale: 1
        )
    }
}
