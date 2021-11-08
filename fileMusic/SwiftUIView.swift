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
    @State var dn = NemesisDownload.shared
    @State var alertMessage: String?
    @State var isShowingAlert = false
    @State var url: URL? {
        didSet {
            guard let url = url else { return }
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
    @State var showingFormats = false
    @State var formatsSheet: ActionSheet?

    var body: some View {
        List {
            if url != nil {
                Text(url?.absoluteString ?? "nil?")
            }
            
            if info != nil {
                Text(info?.title ?? "nil?")
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
    
    func extractInfo(url: URL) {
        print("extractInfo \(url.description)")
        guard let youtubeDL = youtubeDL else {
            loadPythonModule()
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let (_, info) = try youtubeDL.extractInfo(url: url)
                DispatchQueue.main.async {
                    self.info = info
                    check(info: info)
                }
            }
            catch {
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
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                youtubeDL = try YoutubeDL()
                DispatchQueue.main.async {
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
        YoutubeDL.downloadPythonModule { error in
            DispatchQueue.main.async {
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
        guard let formats = info?.formats else { return }
        
        formatsSheet = ActionSheet(title: Text("YouTube Download"), message: Text(info?.description ?? "default"), buttons: [
            .default(Text("Download"),
                     action: {
                         self.download(format: formats.last!, start: true, faster: false)
                     })
        ])
        // 이게 추가되어야 아래 액션시트가 나온다.
        DispatchQueue.main.async {
            showingFormats = true
        }
    }
    
    func download(format: Format, start: Bool, faster: Bool) {
        print("download format.description \(format.description)")
        let kind: NemesisDownload.Kind = .videoOnly
        print("download url \(url), requestUrl \(format.urlRequest)")
        let docuPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.path
        var requests: [URLRequest] = []
        
        if faster, let size = format.filesize {
            if !FileManager.default.createFile(atPath: docuPath, contents: Data(), attributes: nil) {
                print(#function, "couldn't create \(docuPath)")
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

        let tasks = requests.map { dn.download(request: $0, kind: kind) }

        if start {
            do {
                try "".write(to: kind.url, atomically: false, encoding: .utf8)
            }
            catch {
                print(error)
            }
            dn.t0 = ProcessInfo.processInfo.systemUptime
            tasks.first?.resume()
        }
        // */
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
    }
}

