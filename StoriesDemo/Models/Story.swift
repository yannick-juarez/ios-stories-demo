//
//  Story.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 21/04/2026.
//

import Foundation

struct Story: Identifiable, Hashable {
    
    let id: String
    let canonicalID: String
    let user: User
    let items: [StoryItem]
}
