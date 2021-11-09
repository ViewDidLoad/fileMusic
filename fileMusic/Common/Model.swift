//
//  Model.swift
//  fileMusic
//
//  Created by viewdidload on 2021/11/09.
//  Copyright © 2021 viewdidload soft. All rights reserved.
//

import Foundation

struct RESPONSE_RESULT: Codable {
    var result: String
}

struct RESPONSE_PLAY: Codable {
    let _id: String
    let uuid: String
    let nick: String
    let url: String
    let filename: String
}

struct PLAY_HISTORY {
    let uuid: String
    let nick: String
    let playTime: String
    let url: String
    let filename: String
}
