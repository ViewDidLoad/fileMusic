//
//  API.swift
//  fileMusic
//
//  Created by viewdidload on 2021/11/09.
//  Copyright © 2021 viewdidload soft. All rights reserved.
//

import Foundation

let web_server = "https://www.whenyourapprun.com/filemusic"
let remote_server = "https://www.viewdidload.shop/filemusic"

// Session config
func getSessionNoToken(second: TimeInterval) -> URLSession {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = TimeInterval(second)
    return URLSession(configuration: config)
}

func getSession(second: TimeInterval) -> URLSession {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = TimeInterval(second)
    let token = UserDefaults.standard.string(forKey: "token") ?? "token"
    let authValue = "\(token)"
    config.httpAdditionalHeaders = ["Authorization": authValue]
    return URLSession(configuration: config)
}

func registerNick(success: @escaping (RESPONSE_RESULT) -> Void) {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = TimeInterval(5)
    let session = URLSession(configuration: config)
    guard let url = URL(string: web_server + "/registerNick") else {
        print("url error")
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    let os = getOS()
    let uuid = getUUID()
    let nick = getNick()
    let locale = getLocale()
    let version = getVersion()
    let formDataString = "os=\(os)&uuid=\(uuid)&nick=\(nick)&locale=\(locale)&version=\(version)"
    let formEncodedData = formDataString.data(using: .utf8)
    request.httpBody = formEncodedData
    session.dataTask(with: request) { (rData, response, _) in
        guard let data = rData else { return }
        do {
            let response_result = try JSONDecoder().decode(RESPONSE_RESULT.self, from: data)
            success(response_result)
        } catch { print("JSONDecoder error \(error.localizedDescription)") }
    }.resume()
}

func registerPlay(url: String, filename: String, success: @escaping (RESPONSE_RESULT) -> Void) {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = TimeInterval(5)
    let session = URLSession(configuration: config)
    guard let url = URL(string: web_server + "/registerPlay") else {
        print("url error")
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    let uuid = getUUID()
    let nick = getNick()
    let formDataString = "uuid=\(uuid)&nick=\(nick)&url=\(url)&filename=\(filename)"
    let formEncodedData = formDataString.data(using: .utf8)
    request.httpBody = formEncodedData
    session.dataTask(with: request) { (rData, response, _) in
        guard let data = rData else { return }
        do {
            let response_result = try JSONDecoder().decode(RESPONSE_RESULT.self, from: data)
            success(response_result)
        } catch { print("JSONDecoder error \(error.localizedDescription)") }
    }.resume()
}

func getPlay(success: @escaping ([RESPONSE_PLAY]) -> Void) {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = TimeInterval(5)
    let session = URLSession(configuration: config)
    guard let url = URL(string: web_server + "/getPlay") else {
        print("url error")
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    session.dataTask(with: request) { (rData, response, _) in
        guard let data = rData else { return }
        do {
            let response_result = try JSONDecoder().decode([RESPONSE_PLAY].self, from: data)
            success(response_result)
        } catch { print("JSONDecoder error \(error.localizedDescription)") }
    }.resume()
}

func getAd(success: @escaping ([RESPONSE_AD]) -> Void) {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = TimeInterval(5)
    let session = URLSession(configuration: config)
    guard let url = URL(string: web_server + "/getAd") else {
        print("url error")
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    session.dataTask(with: request) { (rData, response, _) in
        guard let data = rData else { return }
        do {
            let response_result = try JSONDecoder().decode([RESPONSE_AD].self, from: data)
            success(response_result)
        } catch { print("JSONDecoder error \(error.localizedDescription)") }
    }.resume()
}

func downloadURL(url: String, success: @escaping (RESPONSE_RESULT) -> Void) {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = TimeInterval(5)
    let session = URLSession(configuration: config)
    guard let url = URL(string: web_server + "/downloadURL") else {
        print("url error")
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    let uuid = getUUID()
    let nick = getNick()
    let formDataString = "uuid=\(uuid)&nick=\(nick)&url=\(url)"
    let formEncodedData = formDataString.data(using: .utf8)
    request.httpBody = formEncodedData
    session.dataTask(with: request) { (rData, response, _) in
        guard let data = rData else { return }
        do {
            let response_result = try JSONDecoder().decode(RESPONSE_RESULT.self, from: data)
            success(response_result)
        } catch { print("JSONDecoder error \(error.localizedDescription)") }
    }.resume()
}

func getURL(url: String, success: @escaping (RESPONSE_RESULT) -> Void) {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = TimeInterval(5)
    let session = URLSession(configuration: config)
    guard let url = URL(string: web_server + "/getURL") else {
        print("url error")
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    let uuid = getUUID()
    let formDataString = "uuid=\(uuid)&url=\(url)"
    let formEncodedData = formDataString.data(using: .utf8)
    request.httpBody = formEncodedData
    session.dataTask(with: request) { (rData, response, _) in
        guard let data = rData else { return }
        do {
            let response_result = try JSONDecoder().decode(RESPONSE_RESULT.self, from: data)
            success(response_result)
        } catch { print("JSONDecoder error \(error.localizedDescription)") }
    }.resume()
}
