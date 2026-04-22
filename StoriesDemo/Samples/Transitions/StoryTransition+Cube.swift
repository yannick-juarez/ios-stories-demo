//
//  StoryTransition+Cube.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 21/04/2026.
//

import SwiftUI

extension StoryTransition {
    static var cube: StoryTransition {
        cube()
    }

    static func cube(duration: Double = 0.42) -> StoryTransition {
        StoryTransition(
            duration: duration,
            animation: .easeInOut(duration: duration),
            makePreparedStates: { context in
                switch context.direction {
                case .forward:
                    return LayerStates(
                        incoming: cubePageState(rotation: 88, anchor: .leading, offset: context.width),
                        outgoing: PageState.identity()
                    )
                case .backward:
                    return LayerStates(
                        incoming: cubePageState(rotation: -88, anchor: .trailing, offset: -context.width),
                        outgoing: PageState.identity()
                    )
                }
            },
            makeFinalStates: { context in
                switch context.direction {
                case .forward:
                    return LayerStates(
                        incoming: PageState.identity(),
                        outgoing: cubePageState(rotation: -88, anchor: .trailing, offset: -context.width)
                    )
                case .backward:
                    return LayerStates(
                        incoming: PageState.identity(),
                        outgoing: cubePageState(rotation: 88, anchor: .leading, offset: context.width)
                    )
                }
            }
        )
    }

    private static func cubePageState(rotation: Double, anchor: UnitPoint, offset: CGFloat) -> PageState {
        PageState(
            translationX: offset,
            opacity: 1,
            rotationY: rotation,
            rotationAnchor: anchor,
            perspective: 0.72,
            scale: 1
        )
    }
}
