//
//  Extension.swift
//  fileMusic
//
//  Created by viewdidload soft on 2020/09/15.
//  Copyright © 2020 viewdidload soft. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

extension AVAudioFile {
    var duration: TimeInterval {
        return Double(length) / Double(processingFormat.sampleRate)
    }
}

extension AVAudioPlayerNode {
    var current: TimeInterval {
        if let nodeTime = lastRenderTime, let playerTime = playerTime(forNodeTime: nodeTime) {
            //print("sampeTime \(playerTime.sampleTime) / sampleRate \(playerTime.sampleRate) = \(Double(playerTime.sampleTime) / playerTime.sampleRate)")
            return Double(playerTime.sampleTime) / playerTime.sampleRate
        }
        return 0
    }
}

extension Notification.Name {
    static let playFinished = Notification.Name("playFinished")
}
