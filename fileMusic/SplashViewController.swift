//
//  SplashViewController.swift
//  fileMusic
//
//  Created by viewdidload soft on 2020/09/15.
//  Copyright © 2020 viewdidload soft. All rights reserved.
//

import UIKit

class SplashViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 서버에서 광고여부 가져오기
        getAd(success: { ads in
            for ad in ads {
                print("enable \(ad.enable)")
                UserDefaults.standard.set(ad.enable, forKey: "AdEnable")
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // nick 설정
        let nick = UserDefaults.standard.string(forKey: "nick")
        // 지연 실행
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
            if nick == "" || nick == nil {
                let board = UIStoryboard(name: "Main", bundle: nil)
                let vc = board.instantiateViewController(withIdentifier: "nickVC") as! NickViewController
                vc.modalPresentationStyle = .fullScreen
                vc.modalTransitionStyle = .crossDissolve
                self.present(vc, animated: false, completion: nil)
            } else {
                let board = UIStoryboard(name: "Main", bundle: nil)
                let vc = board.instantiateViewController(withIdentifier: "mainVC") as! MainViewController
                vc.modalPresentationStyle = .fullScreen
                vc.modalTransitionStyle = .crossDissolve
                self.present(vc, animated: false, completion: nil)
            }
        }
    }
}
