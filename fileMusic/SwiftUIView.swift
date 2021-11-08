//
//  SwiftUIView.swift
//  fileMusic
//
//  Created by viewdidload on 2021/11/08.
//  Copyright © 2021 viewdidload soft. All rights reserved.
//

import SwiftUI
import YoutubeDL
import PythonKit

struct SwiftUIView: View {
    @State var alertMessage: String?
    
    @State var isShowingAlert = false
    
    @State var url: URL? {
        didSet {
            guard let url = url else {
                return
            }
            
            extractInfo(url: url)
        }
    }
    
    @State var info: Info?
    
    @State var error: Error? {
        didSet {
            alertMessage = error?.localizedDescription
            isShowingAlert = true
        }
    }
    
    @State var youtubeDL: YoutubeDL?
    
    @State var indeterminateProgressKey: String?
    
    @State var isTranscodingEnabled = true
    
    @State var isRemuxingEnabled = true
    
    @State var showingFormats = false
    
    @State var formatsSheet: ActionSheet?

    @State var progress: Progress?
    
    var body: some View {
        List {
            if url != nil {
                Text(url?.absoluteString ?? "nil?")
            }
            
            if info != nil {
                Text(info?.title ?? "nil?")
            }
            
            if let key = indeterminateProgressKey {
                if #available(iOS 14.0, *) {
                    ProgressView(key)
                } else {
                    Text(key)
                }
            }
            
            if let progress = progress {
                if #available(iOS 14.0, *) {
                    ProgressView(progress)
                } else {
                    VStack {
                        Text("\(progress.localizedDescription)")
                        Text("\(progress.localizedAdditionalDescription)")
                    }
                }
            }
            
            youtubeDL?.version.map { Text("youtube_dl version \($0)") }
            
            Button("Paste URL") {
                // https://youtu.be/-n_Kw19q2bM 첨밀밀 노래
                let url = URL(string: "https://youtu.be/-n_Kw19q2bM")
                self.url = url
            }
        }
        .onAppear(perform: {
            if info == nil, let url = url {
                extractInfo(url: url)
            }
        })
        .alert(isPresented: $isShowingAlert) {
            Alert(title: Text(alertMessage ?? "no message?"))
        }
        .actionSheet(isPresented: $showingFormats) { () -> ActionSheet in
            formatsSheet ?? ActionSheet(title: Text("nil?"))
        }
    }
    
    func open(url: URL) {
        print("open \(url.description)")
        UIApplication.shared.open(url, options: [:]) {
            if !$0 {
                alert(message: "Failed to open \(url)")
            }
        }
    }
    
    func extractInfo(url: URL) {
        print("extractInfo \(url.description)")
        guard let youtubeDL = youtubeDL else {
            loadPythonModule()
            return
        }
        
        indeterminateProgressKey = "Extracting info..."
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let (_, info) = try youtubeDL.extractInfo(url: url)
                DispatchQueue.main.async {
                    indeterminateProgressKey = nil
                    self.info = info
                    
                    check(info: info)
                }
            }
            catch {
                indeterminateProgressKey = nil
                guard let pyError = error as? PythonError, case let .exception(exception, traceback: _) = pyError else {
                    self.error = error
                    return
                }
                if (String(exception.args[0]) ?? "").contains("Unsupported URL: ") {
                    DispatchQueue.main.async {
                        self.alert(message: NSLocalizedString("Unsupported URL", comment: "Alert message"))
                    }
                }
            }
        }
    }
    
    func loadPythonModule() {
        print("loadPythonMoudle")
        guard FileManager.default.fileExists(atPath: YoutubeDL.pythonModuleURL.path) else {
            downloadPythonModule()
            return
        }
        indeterminateProgressKey = "Loading Python module..."
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                youtubeDL = try YoutubeDL()
                DispatchQueue.main.async {
                    indeterminateProgressKey = nil
                    
                    url.map { extractInfo(url: $0) }
                }
            }
            catch {
                DispatchQueue.main.async {
                    alert(message: error.localizedDescription)
                }
            }
        }
    }
    
    func downloadPythonModule() {
        print("downloadPythonModule")
        indeterminateProgressKey = "Downloading Python module..."
        YoutubeDL.downloadPythonModule { error in
            DispatchQueue.main.async {
                indeterminateProgressKey = nil
                guard error == nil else {
                    self.alert(message: error?.localizedDescription ?? "nil?")
                    return
                }

                loadPythonModule()
            }
        }
    }

    func alert(message: String) {
        alertMessage = message
        isShowingAlert = true
    }
    
    func check(info: Info?) {
        print("check \(info?.description)")
        guard let formats = info?.formats else {
            return
        }
        
        let _best = formats.filter { !$0.isRemuxingNeeded && !$0.isTranscodingNeeded }.last
        guard let best = _best else { return }
        guard let bestHeight = best.height else { return }
        
        formatsSheet = ActionSheet(title: Text("ChooseFormat"), message: Text("SomeFormatsNeedTranscoding"), buttons: [
            .default(Text(String(format: NSLocalizedString("BestFormat", comment: "Alert action"), bestHeight)),
                     action: {
                        self.download(format: best, start: true, faster: false)
                     }),
            .cancel()
        ])

        DispatchQueue.main.async {
            showingFormats = true
        }
    }
    
    func download(format: Format, start: Bool, faster: Bool) {
        print("download \(format.description)")
        let kind: Downloader.Kind = format.isVideoOnly
            ? (!format.isTranscodingNeeded ? .videoOnly : .otherVideo)
            : (format.isAudioOnly ? .audioOnly : .complete)

        var requests: [URLRequest] = []
        
        if faster, let size = format.filesize {
            if !FileManager.default.createFile(atPath: kind.url.part.path, contents: Data(), attributes: nil) {
                print(#function, "couldn't create \(kind.url.part.lastPathComponent)")
            }

            var end: Int64 = -1
            while end < size - 1 {
                guard var request = format.urlRequest else { fatalError() }
                // https://github.com/ytdl-org/youtube-dl/issues/15271#issuecomment-362834889
                end = request.setRange(start: end + 1, fullSize: size)
                requests.append(request)
            }
        } else {
            guard let request = format.urlRequest else { fatalError() }
            requests.append(request)
        }

        let tasks = requests.map { Downloader.shared.download(request: $0, kind: kind) }

        if start {
            progress = Downloader.shared.progress
            progress?.kind = .file
            progress?.fileOperationKind = .downloading
            do {
                try "".write(to: kind.url, atomically: false, encoding: .utf8)
            }
            catch {
                print(error)
            }
            progress?.fileURL = kind.url

            Downloader.shared.t0 = ProcessInfo.processInfo.systemUptime
            tasks.first?.resume()
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
    }
}
