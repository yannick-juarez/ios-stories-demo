//
//  StoryItem.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 21/04/2026.
//

import Foundation

struct StoryItem: Identifiable, Hashable {
    
    let id: String
    let canonicalID: String
    let imageURL: URL
}
