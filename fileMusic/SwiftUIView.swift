//
//  SwiftUIView.swift
//  fileMusic
//
//  Created by viewdidload on 2021/11/08.
//  Copyright © 2021 viewdidload soft. All rights reserved.
//
/*
 테스트할 때는 이상없이 잘 작동하나 배포를 하면 안됨.
 PythonKit 로딩이 안되는 문제로 앱이 튕김.
 개발자 파악하고 있는거 같으나 패치하지 않은 것으로 추정 됨
 3D 관련 모듈은 파이썬 키트 같은 문제 발생되었으나 스트립 모드 디버깅과 바이너리 파일 제거로 해결했다고 깃헙에 올려 놓았음.
 이부분 추적하기 어려우니 일단 웹모듈로 대체하자.
// */

import SwiftUI
import YoutubeDL
import PythonKit

struct SwiftUIView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var dn = NemesisDownload.shared
    @State var alertMessage: String?
    @State var isShowingAlert = false
    @State var url: URL? {
        didSet {
            guard let url = url else { return }
            extractInfo(url: url)
        }
    }
    @State var info: NemesisInfo?
    @State var downloadStatus: String?
    @State var error: Error? {
        didSet {
            alertMessage = error?.localizedDescription
            isShowingAlert = true
        }
    }
    @State var youtubeDL: NemesisYoutubeDL?//YoutubeDL?
    @State var showingFormats = false
    @State var formatsSheet: ActionSheet?
    @State var download_url = "https://youtu.be/-n_Kw19q2bM"
    @State var isDownloadButtonDisable = true
    
    let pub = NotificationCenter.default.publisher(for: Notification.Name("DownloadStatus"))

    var body: some View {
        List {
            TextField("input youtube url", text: $download_url, onEditingChanged: { _ in
                print("onEditingChanged")
            }, onCommit: {
                print("input url completed")
                // 공백이 아닐 때 버튼 활성화
                isDownloadButtonDisable = download_url == "" ? true : false
            })
            Button("Download URL") {
                //download_url = "https://youtu.be/-n_Kw19q2bM"
                print("Download URL clicked")
                self.url = URL(string: download_url)
            }
            .disabled(isDownloadButtonDisable)
            youtubeDL?.version.map { Text("youtube_dl version \($0)") }
            if info != nil { Text(info?.title ?? "nil?") }
            if downloadStatus != nil { Text(downloadStatus ?? "nil?") }
        }
        .onAppear(perform: {
            if info == nil, let url = url { extractInfo(url: url) }
        })
        .onReceive(pub, perform: { output in
            if let output_result = output.object as? String {
                self.DownloadStatus(result: output_result)
            }
        })
        .alert(isPresented: $isShowingAlert) { Alert(title: Text(alertMessage ?? "no message?")) }
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
    
    func DownloadStatus(result: String) {
        // 다운로드 상태를 받아보자. 이게 나오면 성공이다.
        print("DownloadStatus receive success \(result)")
        downloadStatus = "Download Status \(result)"
        if result == "completed" {
            // 현재 창을 닫자.
            self.presentationMode.wrappedValue.dismiss()
            // 다운로드 된 파일 갱신
            NotificationCenter.default.post(name: Notification.Name("updateFileList"), object: nil)
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
                youtubeDL = try NemesisYoutubeDL()
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
    
    func check(info: NemesisInfo?) {
        guard let formats = info?.formats else { return }
        if let bestAudio = formats.filter({ $0.isAudioOnly && $0.ext == "m4a" }).last {
            print("_bestAudio \(bestAudio)")
            formatsSheet = ActionSheet(title: Text("YouTube Download"), message: Text(info?.description ?? "default"), buttons: [
                .default(Text("Download"),
                         action: {
                             self.download(format: bestAudio)
                         })
            ])
        }
        // 이게 추가되어야 아래 액션시트가 나온다.
        DispatchQueue.main.async {
            showingFormats = true
        }
    }
    
    func download(format: NemesisFormat) {
        print("download format.description \(format.description)")
        let docuUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        var fileName = info?.description ?? "audio"
        fileName.removeAll(where: { $0.isPunctuation }) // 특수문자 제거
        let saveFileUrl = docuUrl.appendingPathComponent(fileName).appendingPathExtension("m4a")
        print("download saveFileUrl \(saveFileUrl)")
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

