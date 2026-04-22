//
//  User.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 21/04/2026.
//

import Foundation

struct User: Identifiable, Hashable {

    let id: String
    let canonicalID: String
    let username: String
    let avatarURL: URL
}
