//
//  AdUnit.swift
//  fileMusic
//
//  Created by viewdidload on 2021/11/12.
//  Copyright © 2021 viewdidload soft. All rights reserved.
//

import Foundation

enum AdUnit {
    case interstitial
    case reward
    
    var unitID: String {
        switch self {
        case .interstitial:
            return "ca-app-pub-7335522539377881/2816855209"
        case .reward:
            return "ca-app-pub-7335522539377881/4433845746"
        }
    }
}
