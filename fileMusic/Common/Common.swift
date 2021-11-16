//
//  Common.swift
//  fileMusic
//
//  Created by viewdidload soft on 2020/09/15.
//  Copyright © 2020 viewdidload soft. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer

// 폰트 및 색상
let fontName = "AppleSDGothicNeo-Regular"
let enableTextColor = UIColor(displayP3Red: 34/255, green: 34/355, blue: 34/355, alpha: 1.0)
let enableButtonColor = UIColor(red: 254/255, green: 199/255, blue: 0, alpha: 1.0)
let enableBorderColor = UIColor(red: 55/255, green: 55/255, blue: 55/255, alpha: 1.0)

let disableTextColor = UIColor(displayP3Red: 112/255, green: 112/355, blue: 112/355, alpha: 1.0)
let disableButtonColor = UIColor(red: 216/255, green: 215/255, blue: 215/255, alpha: 1.0)
let disableBorderColor = UIColor(red: 112/255, green: 112/255, blue: 112/255, alpha: 1.0)

let titleFontName = "AppleSDGothicNeo-Bold"
let titleFontSize: CGFloat = 34.0
let titleFontColor = UIColor(displayP3Red: 34/255, green: 34/355, blue: 34/355, alpha: 1.0)

let largeFontName = "AppleSDGothicNeo-Bold"
let largeFontSize: CGFloat = 24.0
let largeFontColor = UIColor(displayP3Red: 64/255, green: 64/355, blue: 64/355, alpha: 1.0)

let bodyBoldFontName = "AppleSDGothicNeo-Bold"
let bodyBoldFontSize: CGFloat = 18.0
let bodyBoldFontColor = UIColor(displayP3Red: 34/255, green: 34/355, blue: 34/355, alpha: 1.0)

let bodyFontName = "AppleSDGothicNeo-Regular"
let bodyFontSize: CGFloat = 18.0
let bodyFontColor = UIColor(displayP3Red: 34/255, green: 34/355, blue: 34/355, alpha: 1.0)

let mediumFontName = "AppleSDGothicNeo-Regular"
let mediumFontSize: CGFloat = 16.0
let mediumFontColor = UIColor(displayP3Red: 34/255, green: 34/355, blue: 34/355, alpha: 1.0)

let smallFontName = "AppleSDGothicNeo-Regular"
let smallFontSize: CGFloat = 14.0
let smallFontColor = UIColor(displayP3Red: 34/255, green: 34/355, blue: 34/355, alpha: 1.0)


func setupRemoteCommand(title: String, current: TimeInterval, duration: TimeInterval, rate: Float) {
    // 음원 정보
    var nowPlayingInfo = [String : Any]()
    nowPlayingInfo[MPMediaItemPropertyTitle] = title
    // 잠금 화면에서 나오는 이미지, background clear 안됨
    if let image = UIImage(named: "lockscreen") {
        nowPlayingInfo[MPMediaItemPropertyArtwork] =
            MPMediaItemArtwork(boundsSize: image.size) { size in
                return image
        }
    }
    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = current
    nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = rate
    // 플레이 되는 음원 정보 표출
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
}

func ObjectIdToDate(id: String) -> Date {
    var resultDate = Date()
    let endIdx: String.Index = id.index(id.startIndex, offsetBy: 7)
    let hex = id[id.startIndex...endIdx]
    if let offset = UInt32(hex, radix: 16) {
        resultDate = Date(timeIntervalSince1970: TimeInterval(offset))
    }
    return resultDate
}

func getLocale() -> String {
    return Locale.current.identifier
}

func getUUID() -> String {
    var result = ""
    if let uuid = UserDefaults.standard.string(forKey: "uuid") {
        result = uuid
    }
    return result
}

func getNick() -> String {
    var result = ""
    if let nick = UserDefaults.standard.string(forKey: "nick") {
        result = nick
    }
    return result
}

func getVersion() -> String {
    var result = ""
    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
        result = version
    }
    return result
}

func getOS() -> String {
    return "iOS_\(UIDevice.current.systemVersion)"
}

func randomString(length: Int) -> String {
    let letters = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
    var randomString: String = ""
    for _ in 0..<length {
        let randomNumber = Int.random(in: 0..<letters.count)
        randomString.append(letters[randomNumber])
    }
    return randomString
}

func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}
