//
//  YoutubeDownloadView.swift
//  fileMusic
//
//  Created by viewdidload on 2021/11/11.
//  Copyright © 2021 viewdidload soft. All rights reserved.
//

import SwiftUI
import Foundation

struct YoutubeDownloadView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var download_url = ""//"https://youtu.be/-n_Kw19q2bM" <- 첨밀밀
    @State var isDownloadButtonDisable = true
    @State var isCheckButtonDisable = true
    @State var isLoadingViewEnable = false
    @State var state = "Status "
    let checkTimer = Timer.publish(every: 9, on: .main, in: .common).autoconnect()
    
    var body: some View {
        LoadingView(isShowing: .constant(isLoadingViewEnable)) {
            List {
                Text("YouTube Download")
                TextField("input youtube url", text: $download_url, onEditingChanged: { _ in
                    print("onEditingChanged")
                }, onCommit: {
                    print("input url completed")
                    // 공백이 아닐 때 버튼 활성화
                    isDownloadButtonDisable = download_url == "" ? true : false
                })
                Button("Download URL") {
                    print("Download URL clicked")
                    // 여기서 서버에 요청을 하자.
                    downloadURL(download_url: download_url) { msg in
                        print("downloadURL \(msg.result)")
                        state = "Status : start download"
                        isDownloadButtonDisable = true
                        isCheckButtonDisable = false
                        isLoadingViewEnable = true
                    }
                }
                .disabled(isDownloadButtonDisable)
                Text(state)
                Button("Download Check") {
                    checkDownload()
                }
                .disabled(isCheckButtonDisable)
                .onReceive(checkTimer) { input in
                    //print("checkTimer \(input)")
                    // 체크 버튼이 활성화 될 때 체크하자.
                    if isCheckButtonDisable == false {
                        checkDownload()
                    } // end_if isCheckButtonDisable = false {
                }
            } // end_List
        }
    }
    
    // 다운로드 상태 체크
    func checkDownload() {
        checkURL(check_url: download_url) { msg in
            print("checkURL \(msg.result)")
            if msg.result != "" {
                state = "Status : Downloading..."
                isCheckButtonDisable = true
                // 타이머 중지
                checkTimer.upstream.connect().cancel()
                // 로딩뷰 감추기
                isLoadingViewEnable = false
                //*/ 서버에 요청해서 파일을 다운받아서 도큐먼트에 저장하자.
                getFileData(filename: msg.result) { msg in
                    print("getFileData \(msg.result)")
                    state = "Status : Download Completed."
                    // 몇 초 후에 창을 닫자.
                    DispatchQueue.main.asyncAfter(deadline: .now() + .microseconds(1500)) {
                        // 현재 창을 닫자.
                        self.presentationMode.wrappedValue.dismiss()
                        // 다운로드 된 파일 갱신
                        NotificationCenter.default.post(name: Notification.Name("updateFileList"), object: nil)
                    }
                }
                // */
            } else {
                // 주로 이게 가장 많이 표시되므로 3~4 개 정도 안내문구를 가지고 돌려서 보여줄 것.
                state = "Status : Downloading"
            }
        }
    }
    
}

struct ActivityIndicator: UIViewRepresentable {
    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style

    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: style)
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}

struct LoadingView<Content>: View where Content: View {
    @Binding var isShowing: Bool
    var content: () -> Content

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                self.content()
                    .disabled(self.isShowing)
                    .blur(radius: self.isShowing ? 0.8 : 0)

                VStack {
                    Text("Downloading...")
                    ActivityIndicator(isAnimating: .constant(true), style: .large)
                }
                .frame(width: geometry.size.width / 2,
                       height: geometry.size.height / 5)
                .background(Color.secondary.colorInvert())
                .foregroundColor(Color.primary)
                .cornerRadius(20)
                .opacity(self.isShowing ? 0.6 : 0)

            }
        }
    }
}

struct YoutubeDownloadView_Previews: PreviewProvider {
    static var previews: some View {
        YoutubeDownloadView()
    }
}
