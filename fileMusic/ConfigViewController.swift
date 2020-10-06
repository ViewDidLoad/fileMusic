//
//  ConfigViewController.swift
//  fileMusic
//
//  Created by viewdidload soft on 2020/10/07.
//  Copyright © 2020 viewdidload soft. All rights reserved.
//

import UIKit
import AVKit

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
        // 파일을 못 가져옴, 왜 그럴까?
        if let fileurl = Bundle.main.url(forResource: "fileMusicDemoSmall", withExtension: "mp4") {
            let player = AVPlayer(url: fileurl)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.videoGravity = .resize
            playerLayer.frame = sender.frame
            playerLayer.name = fileurl.deletingPathExtension().lastPathComponent
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
