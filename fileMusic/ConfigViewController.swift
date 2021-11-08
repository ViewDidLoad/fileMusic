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

class ConfigViewController: UIViewController {
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var movieView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var movieLabel: UILabel!
    @IBOutlet weak var bottomView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 애드몹 광고창 설정
        let bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait, origin: CGPoint.zero)
        bannerView.adUnitID = "ca-app-pub-7335522539377881/7377884882"
        bannerView.rootViewController = self
        bannerView.delegate = self
        bottomView.addSubview(bannerView)
        bannerView.load(GADRequest())
        // 동영상 플레이 끝났을 때 알기 위해 노티 추가
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying(_:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)
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
    
    @IBAction func playButtonTouched(_ sender: UIButton) {
        print("playButtonTouched")
        // 파일을 못 가져옴, 왜 그럴까? 찾았다. build phases - bundle resources 에 이 파일이 없어서 그럼, 추가하니 잘나옴
        //if let url = Bundle.main.url(forResource: "fileMusicDemoSmall", withExtension: "mp4") {
        if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let player = AVPlayer(url: url)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.videoGravity = .resize
            playerLayer.frame = sender.frame
            playerLayer.name = url.deletingPathExtension().lastPathComponent
            movieView.layer.addSublayer(playerLayer)
            player.play()
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
}

extension ConfigViewController: GADBannerViewDelegate {
    func adViewDidReceiveAd(_ bannerView: GADBannerView) // 광고 정보를 받았을 때
    {
        //print("adViewDidReceiveAd \(bottomView.frame.height), \(bannerView.frame.height)")
        bannerView.alpha = 0
        // bottomView 상단에 위치
        bannerView.frame.origin = CGPoint.zero
        UIView.animate(withDuration: 0.8, animations: {
            bannerView.alpha = 1.0
        })
    }
    
}
