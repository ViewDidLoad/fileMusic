//
//  NemesisDownload.swift
//  fileMusic
//
//  Created by viewdidload on 2021/11/08.
//  Copyright © 2021 viewdidload soft. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

@available(iOS 12.0, *)
open class NemesisDownload: NSObject {

    public enum Kind: String {
        case complete, videoOnly, audioOnly, otherVideo
        
        public var url: URL {
            do {
                return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    .appendingPathComponent("video")
                    .appendingPathExtension(self != .audioOnly
                                                ? (self == .otherVideo ? "other" : "mp4")
                                                : "m4a")
            }
            catch {
                print(error)
                fatalError()
            }
        }
    }
    
    public static let shared = NemesisDownload(backgroundURLSessionIdentifier: "YoutubeDL")
    
    open var session: URLSession = URLSession.shared
    
    let decimalFormatter = NumberFormatter()
    
    let percentFormatter = NumberFormatter()
    
    let dateComponentsFormatter = DateComponentsFormatter()
    
    var t = ProcessInfo.processInfo.systemUptime
    
    open var t0 = ProcessInfo.processInfo.systemUptime
    
    init(backgroundURLSessionIdentifier: String?) {
        super.init()
        
        decimalFormatter.numberStyle = .decimal

        percentFormatter.numberStyle = .percent
        percentFormatter.minimumFractionDigits = 1
        
        var configuration: URLSessionConfiguration
        if let identifier = backgroundURLSessionIdentifier {
            configuration = URLSessionConfiguration.background(withIdentifier: identifier)
        } else {
            configuration = .default
        }

        configuration.networkServiceType = .responsiveAV
        
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        print(session, "created")
    }

    func removeItem(at url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
            print(#function, "removed", url.lastPathComponent)
        }
        catch {
            let error = error as NSError
            if error.domain != NSCocoaErrorDomain || error.code != CocoaError.fileNoSuchFile.rawValue {
                print(#function, error)
            }
        }
    }
    
    open func download(request: URLRequest, kind: Kind) -> URLSessionDownloadTask {
        removeItem(at: kind.url)

        let task = session.downloadTask(with: request)
        task.taskDescription = kind.rawValue
//        print(#function, request, trace)
        task.priority = URLSessionTask.highPriority
        return task
    }
    
}

@available(iOS 12.0, *)
extension NemesisDownload: URLSessionDelegate {
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print(#function, session, error ?? "no error")
    }
    
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print(#function, session)
    }
}

@available(iOS 12.0, *)
extension NemesisDownload: URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print(#function, session, task, error)
        }
    }
}

@available(iOS 12.0, *)
extension NemesisDownload: URLSessionDownloadDelegate {
    fileprivate func export(_ url: URL) {
        PHPhotoLibrary.shared().performChanges({
            _ = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            //                            changeRequest.contentEditingOutput = output
        }) { (success, error) in
            print(#function, success, error ?? "")
        }
    }
        
    func assemble(to url: URL, size: UInt64) -> UInt64 {
        let partURL = url.appendingPathExtension("part")
        FileManager.default.createFile(atPath: partURL.path, contents: nil, attributes: nil)
        
        var offset: UInt64 = 0
        
        do {
            let file = try FileHandle(forWritingTo: partURL)
            
            repeat {
                let part = url.appendingPathExtension("part-\(offset)")
                let data = try Data(contentsOf: part, options: .alwaysMapped)
                
                if #available(iOS 13.0, *) {
                    try file.seek(toOffset: offset)
                } else {
                    file.seek(toFileOffset: offset)
                }
                
                file.write(data)
                
                removeItem(at: part)
                
                offset += UInt64(data.count)
            } while offset < size - 1
        }
        catch {
            print(#function, error)
        }
        
        removeItem(at: url)
        
        do {
            try FileManager.default.moveItem(at: partURL, to: url)
        }
        catch {
            print(#function, error)
        }
        
        return offset
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let (_, range, size) = (downloadTask.response as? HTTPURLResponse)?.contentRange
            ?? (nil, -1 ..< -1, -1)
//        print(#function, session, location)
        
        let kind = Kind(rawValue: downloadTask.taskDescription ?? "") ?? .complete

        do {
            if range.isEmpty {
                removeItem(at: kind.url)
                try FileManager.default.moveItem(at: location, to: kind.url)
            } else {
                let part = kind.url.appendingPathExtension("part-\(range.lowerBound)")
                removeItem(at: part)
                try FileManager.default.moveItem(at: location, to: part)

                guard range.upperBound >= size else {
                    session.getTasksWithCompletionHandler { (_, _, tasks) in
                        tasks.first {
                            $0.originalRequest?.url == downloadTask.originalRequest?.url
                                && ($0.originalRequest?.value(forHTTPHeaderField: "Range") ?? "")
                                .hasPrefix("bytes=\(range.upperBound)-") }?
                            .resume()
                    }
                    return
                }
            }
            
            session.getTasksWithCompletionHandler { (_, _, tasks) in
                print(#function, tasks)
                if let task = tasks.first(where: {
                    let range = $0.originalRequest?.value(forHTTPHeaderField: "Range") ?? ""
                    return $0.state == .suspended && (range.isEmpty || range.hasPrefix("bytes=0-"))
                }) {
                    DispatchQueue.main.async {
                        task.taskDescription.flatMap { Kind(rawValue: $0) }.map { kind in
                            do {
                                try "".write(to: kind.url, atomically: false, encoding: .utf8)
                            }
                            catch {
                                print(error)
                            }
                        }
                    }
                    task.resume()
                }
            }
            
            switch kind {
            case .complete:
                export(kind.url)
            case .videoOnly, .audioOnly:
                DispatchQueue.global(qos: .userInitiated).async {
                    _ = self.assemble(to: kind.url, size: .max)
                }
            case .otherVideo:
                print("otherVideo")
            }
        }
        catch {
            print(error)
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let t = ProcessInfo.processInfo.systemUptime
        guard t - self.t > 0.9 else {
            return
        }
        self.t = t
        
        let elapsed = t - t0
        let (_, range, size) = (downloadTask.response as? HTTPURLResponse)?.contentRange ?? (nil, 0..<0, totalBytesExpectedToWrite)
        let count = range.lowerBound + totalBytesWritten
        let bytesPerSec = Double(count) / elapsed
        let remain = Double(size - count) / bytesPerSec
        
        let percent = percentFormatter.string(from: NSNumber(value: Double(count) / Double(size)))
        print("percent \(percent)")
    }
}
