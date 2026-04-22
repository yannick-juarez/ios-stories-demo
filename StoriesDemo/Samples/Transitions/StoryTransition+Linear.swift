//
//  StoryTransition+Linear.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 21/04/2026.
//

import SwiftUI

extension StoryTransition {
    static var linear: StoryTransition {
        linear()
    }

    static func linear(duration: Double = 0.28) -> StoryTransition {
        StoryTransition(
            duration: duration,
            animation: .easeInOut(duration: duration),
            makePreparedStates: { context in
                switch context.direction {
                case .forward:
                    return LayerStates(
                        incoming: linearPageState(offset: context.width),
                        outgoing: PageState.identity()
                    )
                case .backward:
                    return LayerStates(
                        incoming: linearPageState(offset: -context.width),
                        outgoing: PageState.identity()
                    )
                }
            },
            makeFinalStates: { context in
                switch context.direction {
                case .forward:
                    return LayerStates(
                        incoming: PageState.identity(),
                        outgoing: linearPageState(offset: -context.width)
                    )
                case .backward:
                    return LayerStates(
                        incoming: PageState.identity(),
                        outgoing: linearPageState(offset: context.width)
                    )
                }
            }
        )
    }

    private static func linearPageState(offset: CGFloat) -> PageState {
        PageState(
            translationX: offset,
            opacity: 1,
            rotationY: 0,
            rotationAnchor: .center,
            perspective: 0.72,
            scale: 1
        )
    }
}