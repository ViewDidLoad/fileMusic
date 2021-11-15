//
//  ConfigViewController.swift
//  fileMusic
//
//  Created by viewdidload soft on 2020/10/07.
//  Copyright © 2020 viewdidload soft. All rights reserved.
//

import UIKit
import AVKit
import GoogleMobileAds
import AppTrackingTransparency
import AdSupport

class ConfigViewController: UIViewController {
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var elixirButton: UIButton!
    @IBOutlet weak var elixirLabel: UILabel!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var nickView: UIView!
    @IBOutlet weak var nickLabel: UILabel!
    @IBOutlet weak var nickButon: UIButton!
    @IBOutlet weak var movieView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var movieLabel: UILabel!
    @IBOutlet weak var elixirAddButton: UIButton!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var bottomHeightConstraint: NSLayoutConstraint!
    
    // 구글 애드몹 배너광고창
    var bannerView = GADBannerView()
    // 보상형 전면광고 - 엘릭샤 충전
    var rewardedInterstitialAd: GADRewardedInterstitialAd?
    let reward_id = "ca-app-pub-7335522539377881/3302541567"
    var elixir_count = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // topView
        topView.layer.cornerRadius = 15.0
        topView.layer.borderWidth = 1.0
        topView.layer.borderColor = UIColor.white.cgColor
        // 저장된 엘릭샤 개수 가져와서 표시
        elixir_count = UserDefaults.standard.integer(forKey: "elixir")
        elixirLabel.text = "\(elixir_count)"
        // ElixirAddButton
        elixirAddButton.layer.cornerRadius = 15.0
        elixirAddButton.layer.borderWidth = 1.0
        elixirAddButton.layer.borderColor = UIColor.white.cgColor
        // nickView
        nickView.layer.cornerRadius = 15.0
        nickView.layer.borderWidth = 1.0
        nickView.layer.borderColor = UIColor.white.cgColor
        nickLabel.text = getNick()
        nickButon.layer.cornerRadius = 15.0
        nickButon.layer.borderWidth = 1.0
        nickButon.layer.borderColor = enableBorderColor.cgColor
        nickButon.backgroundColor = enableButtonColor
        nickButon.setTitleColor(enableTextColor, for: .normal)
        // 애드몹 광고창 설정
        let adSize = getFullWidthAdaptiveAdSize(view: bottomView)
        bannerView = GADBannerView(adSize: adSize, origin: CGPoint.zero)
        bannerView.adUnitID = "ca-app-pub-7335522539377881/7377884882"
        bannerView.rootViewController = self
        bannerView.delegate = self
        bottomView.addSubview(bannerView)
        let adEnalbe = UserDefaults.standard.bool(forKey: "AdEnable")
        //*/ 스크린 샷을 위해 광고 중지
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { (status) in
                if adEnalbe {
                    self.bannerView.load(GADRequest())
                }
            }
        } else {
            if adEnalbe {
                bannerView.load(GADRequest())
            }
        }
        // */
        // 전면광고 데이터 가져오자.
        if adEnalbe {
            loadInterstitial()
        }
        // 동영상 플레이 끝났을 때 알기 위해 노티 추가
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying(_:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 바닥 뷰의 크기를 0으로 설정하여 나오지 않도록 하고 광고 데이터 받았을 때 나오도록 함
        bottomHeightConstraint.constant = 0.0
        bannerView.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // 노티 감시 제거
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    @IBAction func closeButtonTouched(_ sender: UIButton) {
        print("closeButtonTouched")
        // 메인 창으로 이동
        let board = UIStoryboard(name: "Main", bundle: nil)
        let vc = board.instantiateViewController(withIdentifier: "mainVC") as! MainViewController
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .crossDissolve
        present(vc, animated: false, completion: nil)
    }
    
    @IBAction func elixirButtonTouched(_ sender: UIButton) {
        if elixir_count > 0 {
            // 광고 설정이 되었을 때만 버튼 보여준다.
            let ad = UserDefaults.standard.bool(forKey: "AdEnable")
            if ad == true {
                // 엘릭샤 카운트 감소
                elixir_count -= 1
            }
            UserDefaults.standard.set(elixir_count, forKey: "elixir")
            elixirLabel.text = "\(elixir_count)"
            // 배너광고를 감추자.
            bannerView.isHidden = true
            bottomHeightConstraint.constant = 0.0
            UIView.animate(withDuration: 0.8) {
                self.view.layoutIfNeeded()
            }
        } else {
            // 설정화면에서 엘릭샤 버튼을 터치하여 전면광고를 시청 한 후 다시 시도하세요.
            let alert = UIAlertController(title: "Elixir tribe", message: "Go to config and touch the elixir button to view the ad and replenish it.", preferredStyle: UIAlertController.Style.alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
                alert.dismiss(animated: false, completion: nil)
            }
            alert.addAction(okAction)
            present(alert, animated: false, completion: nil)
        }
    }
    
    @IBAction func nickButtonTouched(_ sender: UIButton) {
        // 별명 변경 창으로 이동
        let board = UIStoryboard(name: "Main", bundle: nil)
        let vc = board.instantiateViewController(withIdentifier: "nickVC") as! NickViewController
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .crossDissolve
        present(vc, animated: false, completion: nil)
    }
    
    @IBAction func playButtonTouched(_ sender: UIButton) {
        print("playButtonTouched")
        // 파일을 못 가져옴, 왜 그럴까? 찾았다. build phases - bundle resources 에 이 파일이 없어서 그럼, 추가하니 잘나옴
        if let url = Bundle.main.url(forResource: "fileMusicDemoSmall", withExtension: "mp4") {
            let player = AVPlayer(url: url)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.videoGravity = .resizeAspect
            playerLayer.frame = sender.frame
            playerLayer.name = url.deletingPathExtension().lastPathComponent
            movieView.layer.addSublayer(playerLayer)
            player.play()
        }
        
    }
    
    @IBAction func elixirAddButtonTouched(_ sender: UIButton) {
        // 데이터 가져왔으면 전면 광고 띄워보자.
        if let ad = rewardedInterstitialAd {
            ad.present(fromRootViewController: self) {
                if let reward = self.rewardedInterstitialAd?.adReward {
                    // 1 reward 설정 했는데 10이 오고 있다.
                    print("reward \(reward.amount)")
                    if reward.amount.intValue > 0 {
                        // 가져온 마법 물약 추가분을 저장시킨다.
                        self.elixir_count += 1
                        self.elixirLabel.text = "\(self.elixir_count)"
                        UserDefaults.standard.set(self.elixir_count, forKey: "elixir")
                    }
                }
            }
        } else {
            // 데이터 없음 잠시 후에 다시 시도하세요.
            let alert = UIAlertController(title: "Ad Empty", message: "Please try again later.", preferredStyle: UIAlertController.Style.alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
                alert.dismiss(animated: false, completion: nil)
            }
            alert.addAction(okAction)
            present(alert, animated: false, completion: nil)
        }
    }
    
    @objc func playerDidFinishPlaying(_ noti: Notification) {
        if let playerItem = noti.object as? AVPlayerItem {
            if let assetItem = playerItem.asset as? AVURLAsset {
                let url = assetItem.url
                let fileName = url.deletingPathExtension().lastPathComponent
                movieView.layer.sublayers?.forEach { layer in
                    if layer.name == fileName { layer.removeFromSuperlayer() }
                }
            }
        }
    }
    
    fileprivate func getFullWidthAdaptiveAdSize(view: UIView) -> GADAdSize {
        let frame = { () -> CGRect in
            if #available(iOS 11.0, *) {
                return view.frame.inset(by: view.safeAreaInsets)
            } else {
                return view.frame
            }
        }()
        return GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(frame.size.width)
    }
    
    fileprivate func loadInterstitial() {
        let request = GADRequest()
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { (status) in
                //보상형 전면광고
                GADRewardedInterstitialAd.load(withAdUnitID: self.reward_id, request: request) { (ad, err) in
                    if let error = err {
                        print("Failed to load Reward Interstitial ad error \(error.localizedDescription)")
                        return
                    }
                    if let reward_ad = ad {
                        self.rewardedInterstitialAd = reward_ad
                        self.rewardedInterstitialAd!.fullScreenContentDelegate = self
                        print("GADRewardedInterstitialAd load")
                    }
                }
            }
        } else {
            // 보상형 전면광고
            GADRewardedInterstitialAd.load(withAdUnitID: reward_id, request: request) { (ad, err) in
                if let error = err {
                    print("Failed to load Reward Interstitial ad error \(error.localizedDescription)")
                    return
                }
                if let reward_ad = ad {
                    self.rewardedInterstitialAd = reward_ad
                    self.rewardedInterstitialAd!.fullScreenContentDelegate = self
                    print("GADRewardedInterstitialAd load")
                }
            }
        }
    }
}

extension ConfigViewController: GADBannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        bannerView.alpha = 0.0
        bottomHeightConstraint.constant = bannerView.bounds.height
        UIView.animate(withDuration: 0.8) {
            self.view.layoutIfNeeded()
            bannerView.alpha = 1.0
        }
    }
    
    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        print("didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
}

extension ConfigViewController: GADFullScreenContentDelegate {
    // MARK: - GADFullScreenContentDelegate
    func adDidPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad did present full screen content.")
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad failed to present full screen content with error \(error.localizedDescription).")
        // 광고시청 오류 : 딱히 넣지 말자, 나중에 생각나면 추가
    }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad did dismiss full screen content.")
        // 광고 시청 : 딱히 넣지 말자, 나중에 생각나면 추가
    }
}
