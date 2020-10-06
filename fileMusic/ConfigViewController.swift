//
//  ConfigViewController.swift
//  fileMusic
//
//  Created by viewdidload soft on 2020/10/07.
//  Copyright © 2020 viewdidload soft. All rights reserved.
//

import UIKit

class ConfigViewController: UIViewController {
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var bottomView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
    
}
