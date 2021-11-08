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
                         self.download(format: formats.last!)
                     })
        ])
        // 이게 추가되어야 아래 액션시트가 나온다.
        DispatchQueue.main.async {
            showingFormats = true
        }
    }
    
    func download(format: Format) {
        print("download format.description \(format.description)")
        let docuUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let saveFileUrl = docuUrl.appendingPathComponent(info?.description ?? "video").appendingPathExtension("mp4")
        //print("download saveFileName \(saveFileUrl)")
        guard let request = format.urlRequest else { fatalError() }
        let task = dn.download(request: request, save: saveFileUrl)
        // 여기서 더미로 저장을 안하면 저장이 안된다.
        do {
            try "".write(to: saveFileUrl, atomically: false, encoding: .utf8)
        } catch { print("saveFileUrl write error \(error.localizedDescription)") }
        dn.t0 = ProcessInfo.processInfo.systemUptime
        task.resume()
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
    }
}

