import Foundation
import SwiftUI

struct Theme: Identifiable {
    
    struct Surfaces {
        let railBackgroundColor: Color
        let canvasColor: Color
        let secondaryCanvasColor: Color
    }

    struct Text {
        let primaryColor: Color
        let secondaryColor: Color
        let unseenColor: Color
    }

    struct Avatar {
        let imageSize: CGFloat
        let frameSize: CGFloat
        let ringWidth: CGFloat
        let seenRingColor: Color
        let unseenRingGradient: LinearGradient
    }

    struct Viewer {
        let backgroundColor: Color
        let chromeColor: Color
        let badgeBackgroundColor: Color
        let buttonBackgroundColor: Color
        let progressTrackColor: Color
        let progressFillColor: Color
    }

    let id: String
    let title: String
    let tintColor: Color
    let surfaces: Surfaces
    let text: Text
    let avatar: Avatar
    let viewer: Viewer
    let likeColor: Color
    let preferredColorScheme: ColorScheme?

    static let allThemes: [Theme] = [.rainbow, .dualCamera]

    static func make(for id: String) -> Theme {
        allThemes.first(where: { $0.id == id }) ?? .rainbow
    }
}
