//
//  NemesisYoutubeDL.swift
//  fileMusic
//
//  Created by viewdidload on 2021/11/09.
//  Copyright © 2021 viewdidload soft. All rights reserved.
//

import Foundation
import PythonKit
import PythonSupport

public struct NemesisInfo: CustomStringConvertible {
    let info: PythonObject

    var dict: [String: PythonObject]? {
        Dictionary(info)
    }

    public var title: String? {
        dict?["title"].flatMap { String($0) }
    }

    var format: NemesisFormat? {
        dict.map { NemesisFormat(format: $0) }
    }
    
    public var formats: [NemesisFormat] {
        let array: [PythonObject]? = dict?["formats"].flatMap { Array($0) }
        let dicts: [[String: PythonObject]?]? = array?.map { Dictionary($0) }
        return dicts?.compactMap { $0.flatMap { NemesisFormat(format: $0) } } ?? []
    }
    
    public var description: String {
        "\(dict?["title"] ?? "no title?")"
    }
}

let nemesisChunkSize: Int64 = 10_000_000

@dynamicMemberLookup
public struct NemesisFormat: CustomStringConvertible {
    public let format: [String: PythonObject]
    
    var url: URL? { self[dynamicMember: "url"].flatMap { URL(string: $0) } }
    
    var httpHeaders: [String: String] {
        format["http_headers"].flatMap { Dictionary($0) } ?? [:]
    }
    
    public var urlRequest: URLRequest? {
        guard let url = url else {
            return nil
        }
        var request = URLRequest(url: url)
        for (field, value) in httpHeaders {
            request.addValue(value, forHTTPHeaderField: field)
        }
        
        return request
    }
    
    public var height: Int? { format["height"].flatMap { Int($0) } }
    
    public var filesize: Int64? { format["filesize"].flatMap { Int64($0) } }
    
    public var isAudioOnly: Bool { self.vcodec == "none" }
    
    public var isVideoOnly: Bool { self.acodec == "none" }
    
    public var description: String {
        "\(format["format"] ?? "no format?") \(format["ext"] ?? "no ext?") \(format["vcodec"] ?? "no vcodec?") \(format["filesize"] ?? "no size?")"
    }
    
    public subscript(dynamicMember key: String) -> String? {
        format[key].flatMap { String($0) }
    }
}

public let NemesisDefaultOptions: PythonObject = [
    "format": "bestvideo,bestaudio[ext=m4a]",
    "nocheckcertificate": true,
]

open class NemesisYoutubeDL: NSObject {
    public enum Error: Swift.Error {
        case noPythonModule
    }
    
    public static var shouldDownloadPythonModule: Bool {
        do {
            _ = try NemesisYoutubeDL()
            return false
        }
        catch Error.noPythonModule {
            return true
        }
        catch {
            guard let error = error as? PythonError,
                  case let .exception(e, _) = error,
                  e.description == "No module named 'youtube_dl'" else { // FIXME: better way?
                return false
            }
            return true
        }
    }
    
    public static let latestDownloadURL = URL(string: "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp")!
    
    public static var pythonModuleURL: URL = {
        guard let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
                .appendingPathComponent("io.github.kewlbear.youtubedl-ios") else { fatalError() }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        }
        catch {
            fatalError(error.localizedDescription)
        }
        return directory.appendingPathComponent("yt_dlp")
    }()
    
    public let version: String?
    
    internal let pythonObject: PythonObject

    internal let options: PythonObject
    
    public init(options: PythonObject = NemesisDefaultOptions) throws {
        guard FileManager.default.fileExists(atPath: Self.pythonModuleURL.path) else {
            throw Error.noPythonModule
        }
        // 배포하면 이 부분에서 로딩이 안되어서 작동 안되는거 같음, 억지로 개발자가 뭘 막아 놓은거 같다. 2021.11.11. 여기까지 추적도 힘들었다.
        let sys = try Python.attemptImport("sys")
        if !(Array(sys.path) ?? []).contains(Self.pythonModuleURL.path) {
            sys.path.insert(1, Self.pythonModuleURL.path)
        }
        
        runSimpleString("""
            class Pop:
                pass

            import subprocess
            subprocess.Popen = Pop
            """)
        
        let pythonModule = try Python.attemptImport("yt_dlp")
        pythonObject = pythonModule.YoutubeDL(options)
        
        self.options = options
        
        version = String(pythonModule.version.__version__)
    }
    
    open func download(url: URL, urlSession: URLSession = .shared, completionHandler: @escaping (Result<URL, Swift.Error>) -> Void) {
        DispatchQueue.global().async {
            do {
                let (formats, info) = try self.extractInfo(url: url)
            }
            catch {
                completionHandler(.failure(error))
            }
        }
    }
    
    open func extractInfo(url: URL) throws -> ([NemesisFormat], NemesisInfo?) {
        print(#function, url)
        let info = try pythonObject.extract_info.throwing.dynamicallyCall(withKeywordArguments: ["": url.absoluteString, "download": false, "process": true])
        
        let format_selector = pythonObject.build_format_selector(options["format"])
        let formats_to_download = format_selector(info)
        var formats: [NemesisFormat] = []
        for format in formats_to_download {
            guard let dict: [String: PythonObject] = Dictionary(format) else { fatalError() }
            formats.append(NemesisFormat(format: dict))
        }
        
        return (formats, NemesisInfo(info: info))
    }
    
    public static func downloadPythonModule(from url: URL = latestDownloadURL, completionHandler: @escaping (Swift.Error?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { (location, response, error) in
            guard let location = location else {
                completionHandler(error)
                return
            }
            do {
                do {
                    try FileManager.default.removeItem(at: pythonModuleURL)
                }
                catch {
                    print(error)
                }
                
                try FileManager.default.moveItem(at: location, to: pythonModuleURL)

                completionHandler(nil)
            }
            catch {
                print(#function, error)
                completionHandler(error)
            }
        }
        
        task.resume()
    }
}
