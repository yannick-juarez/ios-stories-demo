//
//  User+Sample.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 22/04/2026.
//

import Foundation

extension User {

    static let sample = User(
        id: "user1",
        canonicalID: "canonical_user_1",
        username: "johndoe",
        avatarURL: URL(string: "https://picsum.photos/seed/sample-avatar-1/160/160")!
    )
}
