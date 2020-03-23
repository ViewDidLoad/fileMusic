//
//  ViewController.swift
//  fileMusic
//
//  Created by viewdidload soft on 2020/03/05.
//  Copyright © 2020 viewdidload soft. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class FileListCell: UITableViewCell {
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
    var file: AVAudioFile?
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
        // 잠금 화면과 제어센터
        setupRemoteTransportControls()
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
        player = AVAudioPlayerNode()
        audioEngine.attach(player)
        audioEngine.attach(mixer)
        audioEngine.connect(player, to: mixer, format: nil)
        audioEngine.connect(mixer, to: audioEngine.outputNode, format: nil)
        do {
            try audioEngine.start()
        } catch { print("audioEngine error -> \(error.localizedDescription)") }
        
        // 타이머 설정
        playTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [unowned self] (timer) in
            // 실행 중인 상태 프로그레스로 표시
            var progress: Float = 0.0
            if let audio_file = self.file {
                progress = Float(self.player.current / audio_file.duration)
                //print("playTimer \(progress), \(self.player.current), \(audio_file.duration)")
            }
            DispatchQueue.main.async {
                self.playProgressView.progress = progress
            }
        })
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
    
    func playReset() {
        // 새롭게 설정해야 플레이 상태가 초기화 됨
        player.reset()
        player = AVAudioPlayerNode()
        audioEngine.attach(player)
        audioEngine.attach(mixer)
        audioEngine.connect(player, to: mixer, format: nil)
        audioEngine.connect(mixer, to: audioEngine.outputNode, format: nil)
        
        let playMusicTile = data_item[selectIndex]
        DispatchQueue.main.async {
            self.playTitleLabel.text = playMusicTile
            self.playProgressView.progress = 0.0
        }
    }
    
    func play() {
        let music_name = data_item[selectIndex]
        let filename = "\(docuPath)/\(music_name)"
        print("\(music_name) start")
        let fileUrl = URL(fileURLWithPath: filename)
        do {
            file = try AVAudioFile(forReading: fileUrl)
            if let audio_file = file {
                player.scheduleFile(audio_file, at: nil, completionHandler: { print("\(music_name) completed")
                    // next auto play
                    self.nextPlay()
                })
                
                self.setupNowPlaying(title: music_name, current: player.current, duration: audio_file.duration, rate: player.rate)
                
                player.play()
            }
        } catch { print("AVAudioFile error -> \(error.localizedDescription)") }
    }
    
    func nextPlay() {
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
    
    func setupRemoteTransportControls() {
        // 이게 빠져서 제어센터에 나오지 않았음... 젠장
        UIApplication.shared.beginReceivingRemoteControlEvents()
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = true
        // Add handler for Play Command
        commandCenter.playCommand.addTarget { [unowned self] event in
            if self.player.rate == 0.0 {
                self.player.play()
                return .success
            }
            return .commandFailed
        }
        // Add handler for Pause Command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            if self.player.rate == 1.0 {
                self.player.pause()
                return .success
            }
            return .commandFailed
        }
    }
    
    func setupNowPlaying(title: String, current: TimeInterval, duration: TimeInterval, rate: Float) {
        // Define Now Playing Info
        var nowPlayingInfo = [String : Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = title

        if let image = UIImage(named: "lockscreen") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] =
                MPMediaItemArtwork(boundsSize: image.size) { size in
                    return image
            }
        }
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = current
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = rate

        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    /* // 이것대로 했는데 작동 안함
    func setupRemoteCommandCenter(enable: Bool) {
        let remoteCommandCenter = MPRemoteCommandCenter.shared()
        if enable {
            remoteCommandCenter.pauseCommand.addTarget(self, action: #selector(remoteCommandCenterPauseCommandHandler))
            remoteCommandCenter.playCommand.addTarget(self, action: #selector(remoteCommandCenterPlayCommandHandler))
            remoteCommandCenter.stopCommand.addTarget(self, action: #selector(remoteCommandCenterStopCommandHandler))
            remoteCommandCenter.togglePlayPauseCommand.addTarget(self, action: #selector(remoteCommandCenterPlayPauseCommandHandler))
        } else {
            remoteCommandCenter.pauseCommand.removeTarget(self, action: #selector(remoteCommandCenterPauseCommandHandler))
            remoteCommandCenter.playCommand.removeTarget(self, action: #selector(remoteCommandCenterPlayCommandHandler))
            remoteCommandCenter.stopCommand.removeTarget(self, action: #selector(remoteCommandCenterStopCommandHandler))
            remoteCommandCenter.togglePlayPauseCommand.removeTarget(self, action: #selector(remoteCommandCenterPlayPauseCommandHandler))
        }
        remoteCommandCenter.pauseCommand.isEnabled = enable
        remoteCommandCenter.playCommand.isEnabled = enable
        remoteCommandCenter.stopCommand.isEnabled = enable
        remoteCommandCenter.togglePlayPauseCommand.isEnabled = enable
    }
    
    deinit {
        setupRemoteCommandCenter(enable: false)
    }
        
    @objc func remoteCommandCenterPauseCommandHandler() {
        // handle pause
        player.pause()
    }
        
    @objc func remoteCommandCenterPlayCommandHandler() {
        // handle play
        player.play()
    }
        
    @objc func remoteCommandCenterStopCommandHandler() {
        // handle stop
        player.pause()
    }
        
    @objc func remoteCommandCenterPlayPauseCommandHandler() {
        // handle play pause
        if player.rate == 0.0 {
            player.play()
        } else {
            player.pause()
        }
    }
    // */
    
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
        if player.isPlaying { player.pause() }
        selectIndex = indexPath.row
        playReset()
        // 0.5초후에 플레이
        DispatchQueue.main.asyncAfter(deadline: .now() + .microseconds(500)) {
            self.playButton.setImage(UIImage(named: "icon_pause"), for: .normal)
            self.play()
        }
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
            //print("playerTime.sampeTime \(playerTime.sampleTime), \(playerTime.sampleRate)")
            return Double(playerTime.sampleTime) / playerTime.sampleRate
        }
        return 0
    }
}
