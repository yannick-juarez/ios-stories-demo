//
//  StoryTransition.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 21/04/2026.
//

import SwiftUI

struct StoryTransition {
    
    struct Context {
        let direction: StoryTransitionDirection
        let width: CGFloat
    }

    struct PageState {
        let translationX: CGFloat
        let opacity: Double
        let rotationY: Double
        let rotationAnchor: UnitPoint
        let perspective: CGFloat
        let scale: CGFloat

        static func identity() -> Self {
            Self(
                translationX: 0,
                opacity: 1,
                rotationY: 0,
                rotationAnchor: .center,
                perspective: 0.72,
                scale: 1
            )
        }
    }

    struct LayerStates {
        let incoming: PageState
        let outgoing: PageState

        static func identity() -> Self {
            Self(incoming: PageState.identity(), outgoing: PageState.identity())
        }
    }

    let duration: Double
    let animation: Animation

    private let makePreparedStates: (Context) -> LayerStates
    private let makeFinalStates: (Context) -> LayerStates

    init(
        duration: Double,
        animation: Animation,
        makePreparedStates: @escaping (Context) -> LayerStates,
        makeFinalStates: @escaping (Context) -> LayerStates
    ) {
        self.duration = duration
        self.animation = animation
        self.makePreparedStates = makePreparedStates
        self.makeFinalStates = makeFinalStates
    }

    func finalStates(direction: StoryTransitionDirection, width: CGFloat) -> LayerStates {
        makeFinalStates(Context(direction: direction, width: width))
    }

    func preparedStates(direction: StoryTransitionDirection, width: CGFloat) -> LayerStates {
        makePreparedStates(Context(direction: direction, width: width))
    }
}

struct StoryTransitionPageModifier: ViewModifier {
    let state: StoryTransition.PageState

    func body(content: Content) -> some View {
        content
            .compositingGroup()
            .scaleEffect(state.scale)
            .rotation3DEffect(
                .degrees(state.rotationY),
                axis: (x: 0, y: 1, z: 0),
                anchor: state.rotationAnchor,
                perspective: state.perspective
            )
            .offset(x: state.translationX)
            .opacity(state.opacity)
    }
}
