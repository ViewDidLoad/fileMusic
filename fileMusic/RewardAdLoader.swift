//
//  RewardAdLoader.swift
//  fileMusic
//
//  Created by viewdidload on 2021/11/15.
//  Copyright © 2021 viewdidload soft. All rights reserved.
//


import SwiftUI
import GoogleMobileAds

final class RewardedAdLoader: NSObject, GADFullScreenContentDelegate {//GADRewardedAdDelegate {
    
    // MARK: - RewardedAdLoaderError
    enum RewardedAdLoaderError: Error {
        case notReady
        case didNotEarn
        case failedToPresent
    }

    // MARK: - Vars
    private let adUnit: AdUnit
    private var earnedReward: GADAdReward?
    private var rewardedAd: GADRewardedAd?
    private var completion: ((Result<GADAdReward, RewardedAdLoaderError>) -> Void)?
    
    // MARK: - Lifecycle
    init(adUnit: AdUnit) {
        self.adUnit = adUnit
        super.init()
        loadRewardedAd()
    }
    
    deinit {
        rewardedAd = nil
    }

    // MARK: - Public
    func presentAd(completion: ((Result<GADAdReward, RewardedAdLoaderError>) -> Void)? = nil) {
        if rewardedAd != nil {
            self.completion = completion
            if let rootViewController = UIApplication.shared.topMostViewController {
                rewardedAd?.present(fromRootViewController: rootViewController, userDidEarnRewardHandler: {
                    print("rewarded userDidEarnReward")
                })
            }
        } else {
            completion?(.failure(.notReady))
        }
    }
    
    // MARK: - Helper
    private func loadRewardedAd() {
        let request = GADRequest()
        GADRewardedAd.load(withAdUnitID: adUnit.unitID, request: request) { ad, error in
            if let error = error {
                print("Failed to load reward ad with error \(error.localizedDescription)")
            }
            self.rewardedAd = ad
            self.rewardedAd?.fullScreenContentDelegate = self
        }
    }

    // MARK: - GADRewardedAdDelegate
    func rewardedAd(_ rewardedAd: GADRewardedAd, userDidEarn reward: GADAdReward) {
        earnedReward = reward
    }

    func rewardedAd(_ rewardedAd: GADRewardedAd, didFailToPresentWithError error: Error) {
        completion?(.failure(.failedToPresent))
    }

    func rewardedAdDidDismiss(_ rewardedAd: GADRewardedAd) {
        if let reward = earnedReward {
            completion?(.success(reward))
            earnedReward = nil
        } else {
            completion?(.failure(.didNotEarn))
        }

        loadRewardedAd()
    }
}
