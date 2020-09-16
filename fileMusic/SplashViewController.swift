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
    @IBOutlet weak var titleTopConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleTopConstraint.constant = 10
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        titleTopConstraint.constant = UIScreen.main.bounds.midY - titleLabel.bounds.height
        UIView.animate(withDuration: 0.8) {
            self.view.layoutIfNeeded()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 지연 실행
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
            let board = UIStoryboard(name: "Main", bundle: nil)
            let vc = board.instantiateViewController(withIdentifier: "mainVC") as! MainViewController
            vc.modalPresentationStyle = .fullScreen
            vc.modalTransitionStyle = .crossDissolve
            self.present(vc, animated: false, completion: nil)
        }
    }
}
