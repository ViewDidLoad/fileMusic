//
//  ViewController.swift
//  fileMusic
//
//  Created by viewdidload soft on 2020/03/05.
//  Copyright © 2020 viewdidload soft. All rights reserved.
//

import UIKit

class FileListCell: UITableViewCell {
    @IBOutlet weak var fileTitleLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    
}

class ViewController: UIViewController {
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var fileListTableView: UITableView!
    
    @IBOutlet weak var bottomView: UIView!
    
    var data_item = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // tableView
        fileListTableView.rowHeight = UITableView.automaticDimension
        fileListTableView.delegate = self
        fileListTableView.dataSource = self
        
        let fm = FileManager.default
        guard let docuPath = fm.urls(for: .documentDirectory, in: .userDomainMask).first?.path else { return }
        do {
            // 접근한 경로의 디렉토리 내 파일 리스트를 불러옵니다.
            let items = try fm.contentsOfDirectory(atPath: docuPath)
            print("Count \(items.count)")
              for item in items {
                print("Found \(item)")
                data_item.append(item)
              }
        } catch { print("Not Found item") }

    }


}

extension ViewController: UITableViewDelegate {
    
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data_item.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fileListCell", for: indexPath) as! FileListCell
        cell.fileTitleLabel.text = data_item[indexPath.row]
        return cell
    }
}
