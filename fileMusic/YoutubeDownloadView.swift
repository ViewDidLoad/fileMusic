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
    @State var state = "Status "
    let checkTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
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
                }
            }
            .disabled(isDownloadButtonDisable)
            Text(state)
            Button("Download Check") {
                print("Download Check clicked")
                checkURL(check_url: download_url) { msg in
                    print("checkURL \(msg.result)")
                    if msg.result != "" {
                        state = "Status : downloading..."
                        isCheckButtonDisable = true
                        //*/ 서버에 요청해서 파일을 다운받아서 도큐먼트에 저장하자.
                        getFileData(filename: msg.result) { msg in
                            print("getFileData \(msg.result)")
                            state = "Status : download completed."
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
                        state = "Status : ready download configuration"
                    }
                }
            }
            .disabled(isCheckButtonDisable)
            .onReceive(checkTimer) { input in
                print("checkTimer \(input)")
                // 체크 버튼이 활성화 될 때 체크하자.
                if isCheckButtonDisable == false {
                    checkURL(check_url: download_url) { msg in
                        print("checkURL \(msg.result)")
                        if msg.result != "" {
                            state = "Status : downloading..."
                            isCheckButtonDisable = true
                            // 타이머 중지
                            checkTimer.upstream.connect().cancel()
                            //*/ 서버에 요청해서 파일을 다운받아서 도큐먼트에 저장하자.
                            getFileData(filename: msg.result) { msg in
                                print("getFileData \(msg.result)")
                                state = "Status : download completed."
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
                            state = "Status : ready download configuration"
                        }
                    }
                } // end_if isCheckButtonDisable = false {
            }
        }
        
    }
}

struct YoutubeDownloadView_Previews: PreviewProvider {
    static var previews: some View {
        YoutubeDownloadView()
    }
}
