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
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let kind = Kind(rawValue: downloadTask.taskDescription ?? "") ?? .complete
        do {
            // same name already exists 해결 방법
            //try FileManager.default.moveItem(at: location, to: kind.url)
            try FileManager.default.removeItem(at: kind.url)
            print("file remove \(kind.url)")
            try FileManager.default.copyItem(at: location, to: kind.url)
            print("file copy completed \(kind.url)")
        } catch {
            print("File move location \(location) -> \(kind.url) error \(error)")
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
        print("urlSession downloadTask percent \(String(describing: percent)), remain \(remain)")
    }
}
