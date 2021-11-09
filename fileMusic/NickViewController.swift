//
//  NickViewController.swift
//  fileMusic
//
//  Created by viewdidload on 2021/11/09.
//  Copyright © 2021 viewdidload soft. All rights reserved.
//

import UIKit

class NickViewController: UIViewController {
    @IBOutlet weak var nickView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var nameView: UIView!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var nickTextField: UITextField!
    @IBOutlet weak var okButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // nickView
        nickView.layer.cornerRadius = 15.0
        nickView.layer.borderWidth = 1.0
        nickView.layer.borderColor = UIColor.white.cgColor
        // nameView
        nameView.layer.cornerRadius = 15.0
        nameView.layer.borderWidth = 1.0
        nameView.layer.borderColor = enableBorderColor.cgColor
        nickTextField.delegate = self
        // okbutton
        okButton.layer.cornerRadius = 15.0
        okButton.layer.borderWidth = 1.0
        okButton.layer.borderColor = disableBorderColor.cgColor
        okButton.backgroundColor = disableButtonColor
        okButton.setTitleColor(disableTextColor, for: .normal)
        okButton.isEnabled = false
        // observer register
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 저장된 값이 있으면 그 값을 먼저 표현하자.
        let nick = getNick()
        if nick != "" { nickTextField.text = nick }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // observer remove
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    @IBAction func okButtonTouched(_ sender: UIButton) {
        // nick 등록
        if nickTextField.hasText {
            let nick = nickTextField.text
            UserDefaults.standard.set(nick, forKey: "nick")
            // 서버 전송, 서버측 api 구성되면 연결할 것.
            registerNick { msg in
                print("registerNick \(msg.result)")
            }
        }
        // MainVC 이동
        let board = UIStoryboard(name: "Main", bundle: nil)
        let vc = board.instantiateViewController(withIdentifier: "mainVC") as! MainViewController
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .coverVertical
        present(vc, animated: false, completion: nil)
    }
    
    @objc func keyboardWillShow(_ sender: Notification) {
        // get keyboard info
        let userInfo = sender.userInfo! as Dictionary
        let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
        // adjust keyboard height
        let keyboardY = UIScreen.main.bounds.height - keyboardFrame.height
        let verifyY = nickView.frame.origin.y + nickView.frame.height
        print("keyboardY \(keyboardY), verifyY \(verifyY)")
        if verifyY > keyboardY {
            self.view.frame.origin.y = -(verifyY - keyboardY)
        }
        // animate
        let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval
        UIView.animate(withDuration: animationDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func keyboardWillHide(_ sender: Notification) {
        //print("keyboardWillHide")
        // 키보드가 내려갈 때 문자가 있으면 다음 버튼 활성화
        if nickTextField.hasText {
            // nextButton enable
            okButton.setTitleColor(enableTextColor, for: .normal)
            okButton.backgroundColor = enableButtonColor
            okButton.layer.borderColor = enableBorderColor.cgColor
            okButton.isEnabled = true
        } else {
            // nextButton disable
            okButton.setTitleColor(disableTextColor, for: .normal)
            okButton.backgroundColor = disableButtonColor
            okButton.layer.borderColor = disableBorderColor.cgColor
            okButton.isEnabled = false
        }
        let userInfo = sender.userInfo! as Dictionary
        self.view.frame.origin.y = 0
        // animate
        let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval
        UIView.animate(withDuration: animationDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
}

extension NickViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
