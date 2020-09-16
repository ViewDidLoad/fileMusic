//
//  MainViewController.swift
//  fileMusic
//
//  Created by viewdidload soft on 2020/09/15.
//  Copyright © 2020 viewdidload soft. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class FileListCell: UITableViewCell {
    @IBOutlet weak var fileTitleLabel: UILabel!
}

class MainViewController: UIViewController {
    
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
    var file: AVAudioFile?
    // 음원 플레이어
    var audioEngine = AVAudioEngine()
    var player = AVAudioPlayerNode()
    var audioFile: AVAudioFile!
    var selectIndex = 0
    var playTimer:Timer!
    var progress: Float = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 파일 설정
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
        player = AVAudioPlayerNode()
        audioEngine.attach(player)
        audioEngine.connect(player, to: audioEngine.outputNode, format: nil)
        do {
            try audioEngine.start()
        } catch { print("audioEngine error -> \(error.localizedDescription)") }
        // 타이머 설정
        playTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [unowned self] (timer) in
            // 실행 중인 상태 프로그레스로 표시
            if let audio_file = self.file {
                self.progress = Float(self.player.current / audio_file.duration)
                //print("playTimer \(progress), \(self.player.current), \(audio_file.duration)")
            }
            DispatchQueue.main.async {
                self.playProgressView.progress = self.progress
            }
        })
        // 잠금 화면과 제어센터
        setupRemoteTransportControls(player: player)
        // tableView
        fileListTableView.rowHeight = UITableView.automaticDimension
        fileListTableView.delegate = self
        fileListTableView.dataSource = self
        // 노티 설정 - 오디오 중단 발생 알림
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption(notification:)), name: NSNotification.Name("AVAudioSessionInterruptionNotification"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // 이름 순으로 정렬
        data_item.sort()
        DispatchQueue.main.async {
            self.fileListTableView.reloadData()
        }
        // 타이머 실행
        if playTimer.isValid { playTimer.fire() }
    }
    
    @IBAction func touchedPlayButton(_ sender: UIButton) {
        print("player status -> \(player.isPlaying)")
        if player.isPlaying  {
            sender.setImage(UIImage(named: "icon_play"), for: .normal)
            player.pause()
        } else {
            sender.setImage(UIImage(named: "icon_pause"), for: .normal)
            play()
        }
    }
    
    @IBAction func handleInterruption(notification: Notification) {
        // 테스트로 유투브 갔다가 와보니 갔을 때 hadleInterruption Optional([AnyHashable("AVAudioSessionInterruptionTypeKey"): 1])
        // 유튜브 끝났을 때 -> hadleInterruption Optional([AnyHashable("AVAudioSessionInterruptionOptionKey"): 0, AnyHashable("AVAudioSessionInterruptionTypeKey"): 0])
        print("hadleInterruption \(String(describing: notification.userInfo))")
        guard let userInfo = notification.userInfo,
            let value = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let interruptType =  AVAudioSession.InterruptionType(rawValue: value) else {
                return
        }
        
        switch interruptType {
        case .began:
            print("interruptType began")
            self.player.pause()
        case .ended:
            print("interruptType ended")
            // 재시작 가능할 때
            if let optionKey = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt {
                let interruptOption = AVAudioSession.InterruptionOptions(rawValue: optionKey)
                if interruptOption == .shouldResume {
                    self.player.play()
                }
            }
            
        default:
            fatalError()
        }
    }
    
    func playReset() {
        // 새롭게 설정해야 플레이 상태가 초기화 됨
        player.reset()
        player = AVAudioPlayerNode()
        audioEngine.attach(player)
        audioEngine.connect(player, to: audioEngine.outputNode, format: nil)
        
        let playMusicTile = data_item.count > 0 ? data_item[selectIndex] : "sample.mp3"
        DispatchQueue.main.async {
            self.playTitleLabel.text = playMusicTile
            self.playProgressView.progress = 0.0
        }
    }
    
    func play() {
        if data_item.count > 0 {
            // 가져온 파일이 있으면 리스트로 플레이
            let music_name = data_item[selectIndex]
            let filename = "\(docuPath)/\(music_name)"
            print("\(music_name) start")
            let fileUrl = URL(fileURLWithPath: filename)
            do {
                file = try AVAudioFile(forReading: fileUrl)
                if let audio_file = file {
                    player.scheduleFile(audio_file, at: nil, completionHandler: {
                        print("\(music_name) completed")
                        self.nextPlay()
                    })
                    setupRemoteCommand(title: music_name, current: player.current, duration: audio_file.duration, rate: player.rate)
                    player.play()
                }
            } catch { print("AVAudioFile error -> \(error.localizedDescription)") }
        } // 가저온 파일이 없으면 샘플로 플레이 한다.
        else {
            guard let sampleUrl = Bundle.main.url(forResource: "sample", withExtension: "mp3") else { return }
            do {
                file = try AVAudioFile(forReading: sampleUrl)
                if let audio_file = file {
                    player.scheduleFile(audio_file, at: nil, completionHandler: {
                        print("sample.mp3 completed")
                    })
                    setupRemoteCommand(title: "sample.mp3", current: player.current, duration: audio_file.duration, rate: player.rate)
                    self.playTitleLabel.text = "sample.mp3"
                    player.play()
                }
            } catch { print("AVAudioFile error -> \(error.localizedDescription)") }
        }
    }
    
    func nextPlay() {
        if data_item.count > 0 {
            // 파일 리스트가 있을 경우
            selectIndex += 1
            if selectIndex >= data_item.count { selectIndex = 0 }
            // 테이블 셀 선택 바꿔줘야 함
            let indexPath = IndexPath(row: selectIndex, section: 0)
            DispatchQueue.main.async {
                self.fileListTableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableView.ScrollPosition.middle)
            }
            playReset()
            // 0.5초후에 플레이
            DispatchQueue.main.asyncAfter(deadline: .now() + .microseconds(500)) {
                self.play()
            }
        }
    }
    
    func prevPlay() {
        if data_item.count > 0 {
            // 파일 리스트가 있을 경우
            selectIndex -= 1
            if selectIndex < 0 { selectIndex = data_item.count - 1 }
            // 테이블 셀 선택 바꿔줘야 함
            let indexPath = IndexPath(row: selectIndex, section: 0)
            DispatchQueue.main.async {
                self.fileListTableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableView.ScrollPosition.middle)
            }
            playReset()
            // 0.5초후에 플레이
            DispatchQueue.main.asyncAfter(deadline: .now() + .microseconds(500)) {
                self.play()
            }
        }
    }
    
    func setupRemoteTransportControls(player: AVAudioPlayerNode) {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.addTarget { [unowned self] event in
            print("setupRemoteTransportControls event \(event)")
            player.play()
            return .success
        }
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            print("setupRemoteTransportControls event \(event)")
            player.pause()
            return .success
        }
        commandCenter.nextTrackCommand.addTarget { [unowned self] event in
            self.nextPlay()
            return .success
        }
        commandCenter.previousTrackCommand.addTarget { [unowned self] event in
            self.prevPlay()
            return .success
        }
    }
    

}

extension MainViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

extension MainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data_item.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fileCell", for: indexPath) as! FileListCell
        cell.fileTitleLabel.text = data_item[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if player.isPlaying { player.pause() }
        selectIndex = indexPath.row
        playReset()
        // 0.5초후에 플레이
        DispatchQueue.main.asyncAfter(deadline: .now() + .microseconds(500)) {
            self.playButton.setImage(UIImage(named: "icon_pause"), for: .normal)
            self.play()
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .normal, title: "") { (action, view, completionHandler) in
            // 해당 파일 삭제하기
            let remove_item = "\(self.docuPath)/\(self.data_item[indexPath.row])"
            print("selected remove_item \(remove_item)")
            do {
                try self.fm.removeItem(atPath: remove_item)
                self.data_item.remove(at: indexPath.row)
                DispatchQueue.main.async {
                    tableView.reloadData()
                }
            } catch { print("FileManager RemoveItem error \(error.localizedDescription)") }
            completionHandler(true)
        }
        action.image = UIImage(named: "icon_delete")
        action.backgroundColor = .red
        let configuration = UISwipeActionsConfiguration(actions: [action])
        return configuration
    }
}

