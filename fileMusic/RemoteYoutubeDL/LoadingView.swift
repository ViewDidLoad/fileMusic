//
//  LoadingView.swift
//  fileMusic
//
//  Created by viewdidload on 2021/11/12.
//  Copyright © 2021 viewdidload soft. All rights reserved.
//

import SwiftUI

struct LoadingView<Content>: View where Content: View {
    @Binding var isShowing: Bool
    var content: () -> Content
    // 리워드 광고
    private let adLoader = RewardedAdLoader(adUnit: .reward)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                self.content()
                    .disabled(self.isShowing)
                    .blur(radius: self.isShowing ? 0.8 : 0)
                VStack {
                    Text("Downloading...")
                    ActivityIndicator(isAnimating: .constant(true), style: .large)
                    Button("Watch Ad") {
                        adLoader.presentAd { result in
                            switch result {
                            case .success(let reward):
                                print("IR success \(reward.debugDescription)")
                            case .failure(let error):
                                switch error {
                                case .notReady: break
                                case .didNotEarn: break
                                case .failedToPresent: break
                                }
                            }
                        }
                    }
                    .buttonStyle(NemesisButtonStyle())

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

struct NemesisButtonStyle: ButtonStyle {
    var textColor: Color = Color(enableTextColor)
    var backgroundColor: Color = Color(enableButtonColor)
    var borderColor: Color = Color(enableBorderColor)
    var cornerRadius: CGFloat = 15.0
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 200, height: 55, alignment: .center)
            .foregroundColor(textColor)
            .background(RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(backgroundColor))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(borderColor))
    }
}
