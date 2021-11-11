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
