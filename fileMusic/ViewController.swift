//
//  ViewController.swift
//  fileMusic
//
//  Created by viewdidload soft on 2020/03/05.
//  Copyright © 2020 viewdidload soft. All rights reserved.
//

import UIKit
import AVFoundation

class FileListCell: UITableViewCell {
    @IBOutlet weak var cellView: UIView!
    @IBOutlet weak var fileTitleLabel: UILabel!
}

class ViewController: UIViewController {
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var playTitleLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var playProgressView: UIProgressView!
    @IBOutlet weak var fileListTableView: UITableView!
    @IBOutlet weak var bottomView: UIView!

    let fm = FileManager.default
    var docuPath = ""
    var data_item = [String]()
    // 음원 플레이어
    var audioEngine = AVAudioEngine()
    var equalizer: AVAudioUnitEQ!
    var mixer = AVAudioMixerNode()
    var player = AVAudioPlayerNode()
    var audioFile: AVAudioFile!
    var selectIndex = 0
    var playTimer:Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // tableView
        fileListTableView.rowHeight = UITableView.automaticDimension
        fileListTableView.delegate = self
        fileListTableView.dataSource = self
        
        docuPath = fm.urls(for: .documentDirectory, in: .userDomainMask).first!.path
        do {
            // 접근한 경로의 디렉토리 내 파일 리스트를 불러옵니다.
            let items = try fm.contentsOfDirectory(atPath: docuPath)
            //for item in items { data_item.append(item) }
            items.forEach { item in
                data_item.append(item)
            }
        } catch { print("Not Found item") }
        
        // audioEngine 설정
        equalizer = AVAudioUnitEQ(numberOfBands: 5)
        audioEngine.attach(player)
        audioEngine.attach(equalizer)
        audioEngine.attach(mixer)
        audioEngine.connect(player, to: equalizer, format: nil)
        audioEngine.connect(equalizer, to: audioEngine.outputNode, format: nil)
        audioEngine.connect(mixer, to: audioEngine.outputNode, format: nil)
        let bands = equalizer.bands
        let freqs = [60, 230, 910, 4000, 14000]
        for i in 0...(bands.count - 1) {
            bands[i].frequency = Float(freqs[i])
            bands[i].bypass = false
            bands[i].filterType = .parametric
        }
        bands[0].gain = -10.0
        bands[0].filterType = .lowShelf
        bands[1].gain = -10.0
        bands[1].filterType = .lowShelf
        bands[2].gain = -10.0
        bands[2].filterType = .lowShelf
        bands[3].gain = 10.0
        bands[3].filterType = .highShelf
        bands[4].gain = 10.0
        bands[4].filterType = .highShelf
        
        
    }

    @IBAction func touchedPlayButton(_ sender: UIButton) {
        print("player status -> \(player.isPlaying)")
        player = AVAudioPlayerNode()
        
        audioEngine.attach(player)
        audioEngine.connect(player, to: mixer, format: nil)
        
        let filename = "\(docuPath)/\(data_item[selectIndex])"
        let fileUrl = URL(fileURLWithPath: filename)
        
        do {
            let file = try AVAudioFile(forReading: fileUrl)
            player.scheduleFile(file, at: nil, completionHandler: { print("filename completed") })
            do {
                try audioEngine.start()
                player.play()
                // 타이머 실행
                playTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [unowned self] (timer) in
                    // 실행 중인 상태 프로그레스로 표시
                    let progress = Float(self.player.current / file.duration)
                    self.playProgressView.progress = progress
                })
                playTimer.fire()
            } catch { print("audioEngine start error -> \(error.localizedDescription)") }
        } catch { print("AVAudioFile error -> \(error.localizedDescription)") }
        sender.setImage(UIImage(named: "icon_pause"), for: .normal)
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        playTitleLabel.text = data_item[indexPath.row]
        playButton.setImage(UIImage(named: "icon_play"), for: .normal)
        playProgressView.progress = 0.0
        selectIndex = indexPath.row
    }
}

extension AVAudioFile {
    var duration: TimeInterval {
        return Double(length) / Double(processingFormat.sampleRate)
    }
}

extension AVAudioPlayerNode {
    var current: TimeInterval {
        if let nodeTime = lastRenderTime, let playerTime = playerTime(forNodeTime: nodeTime) {
            return Double(playerTime.sampleTime) / playerTime.sampleRate
        }
        return 0
    }
}
