//
//  InterstitialAdLoader.swift
//  fileMusic
//
//  Created by viewdidload on 2021/11/12.
//  Copyright © 2021 viewdidload soft. All rights reserved.
//

import SwiftUI
import GoogleMobileAds

final class InterstitialAdLoader: NSObject, GADFullScreenContentDelegate {
    
    // MARK: - InterstitialAdLoaderError
    enum InterstitialAdLoaderError: Error {
        case notReady
        case failedToPresent
    }

    // MARK: - Vars
    private let adUnit: AdUnit
    private var interstitial: GADInterstitialAd?
    private var completion: ((Result<Bool, InterstitialAdLoaderError>) -> Void)?
    
    // MARK: - Lifecycle
    init(adUnit: AdUnit) {
        self.adUnit = adUnit
        super.init()
        loadInterstitial()
    }
    
    deinit {
        interstitial = nil
    }
    
    // MARK: - Public
    func presentAd(completion: ((Result<Bool, InterstitialAdLoaderError>) -> Void)? = nil) {
        if interstitial != nil {
            self.completion = completion
            if let rootViewController = UIApplication.shared.topMostViewController {
                interstitial?.present(fromRootViewController: rootViewController)
            }
        } else {
            completion?(.failure(.notReady))
        }
    }

    // MARK: - Helper
    private func loadInterstitial() {
        let request = GADRequest()
        GADInterstitialAd.load(withAdUnitID: adUnit.unitID, request: request) { ad, error in
            if let error = error {
                print("Failed to load interstitial ad with error \(error.localizedDescription)")
            }
            self.interstitial = ad
            self.interstitial?.fullScreenContentDelegate = self
        }
    }
    
    // MARK: - GADFullScreenContentDelegate
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad did fail to present full screen content.")
    }

    /// Tells the delegate that the ad presented full screen content.
    func adDidPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad did present full screen content.")
    }

    /// Tells the delegate that the ad dismissed full screen content.
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad did dismiss full screen content.")
    }

    /*/ MARK: - GADInterstitialDelegate
    func interstitialDidFail(toPresentScreen ad: GADInterstitial) {
        completion?(.failure(.failedToPresent))
        loadInterstitial()
    }
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        completion?(.success(true))
        loadInterstitial()
    }
    // */
}
