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

    // 플레이 파일 목록
    let fm = FileManager.default
    var docuPath = ""
    var data_item = [URL]()
    // 음원 플레이어
    let engine = AVAudioEngine()
    let player = AVAudioPlayerNode()
    let reverb = AVAudioUnitReverb()
    var sourceFile: AVAudioFile?
    var format: AVAudioFormat?
    // 선택된 파일 및 표시
    var selectIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 파일 설정 -> 리스트에 url을 넣자
        docuPath = fm.urls(for: .documentDirectory, in: .userDomainMask).first!.path
        do {
            // 접근한 경로의 디렉토리 내 파일 리스트를 불러옵니다.
            let items = try fm.contentsOfDirectory(atPath: docuPath)
            for item in items {
                let filename = "\(docuPath)/\(item)"
                let fileUrl = URL(fileURLWithPath: filename)
                data_item.append(fileUrl)
            }
        } catch { print("Not Found item") }
        // 가져올 파일이 없으면 샘플 파일을 로딩
        if data_item.count == 0 {
            if let fileUrl_1 = Bundle.main.url(forResource: "Blumenlied", withExtension: "mp3") {
                data_item.append(fileUrl_1)
            }
            if let fileUrl_2 = Bundle.main.url(forResource: "Canon", withExtension: "mp3") {
                data_item.append(fileUrl_2)
            }
        }
        // engine 설정
        engine.attach(player)
        engine.attach(reverb)
        // Set the desired reverb parameters
        reverb.loadFactoryPreset(.mediumHall)
        reverb.wetDryMix = 50
        // connect the nodes
        engine.connect(player, to: reverb, format: format)
        engine.connect(reverb, to: engine.mainMixerNode, format: format)
        do {
            try engine.start()
        } catch { print("engine error -> \(error.localizedDescription)") }
                
        // 잠금 화면과 제어센터 사용할 내용 등록
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.addTarget { [unowned self] event in
            self.player.play()
            return .success
        }
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            self.player.pause()
            return .success
        }
        commandCenter.nextTrackCommand.addTarget { [unowned self] event in
            self.selectIndex += 1
            if self.selectIndex >= data_item.count { self.selectIndex = 0 }
            musicPlay(music: data_item[selectIndex])
            return .success
        }
        commandCenter.previousTrackCommand.addTarget { [unowned self] event in
            self.selectIndex -= 1
            if self.selectIndex < 0 { self.selectIndex = self.data_item.count - 1 }
            musicPlay(music: data_item[selectIndex])
            return .success
        }
        // tableView
        fileListTableView.delegate = self
        fileListTableView.dataSource = self
        fileListTableView.rowHeight = UITableView.automaticDimension
        fileListTableView.dragDelegate = self
        fileListTableView.dropDelegate = self
        fileListTableView.dragInteractionEnabled = true
        // 알람 설정 - 오디오 중단 발생 알림
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
        // 알람 설정 - 해드폰에서 스피커 등 변경될 때
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        DispatchQueue.main.async {
            self.fileListTableView.reloadData()
        }
        // 타이머 설정 - 프로그래스 바에 얼마만큼 플레이 중인지 표시
        let timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true, block: { [unowned self] (timer) in
            // 플레이어 플레이 중일 때만
            if self.player.isPlaying {
                // 프로그레스로 표시
                if let audioDuration = self.sourceFile?.duration {
                    let progress = Float(self.player.current / audioDuration)
                    let log_str = String(format: "timer -> %.2f / %.2f = %.3f", self.player.current, audioDuration, progress)
                    print(log_str)
                    DispatchQueue.main.async {
                        self.playProgressView.progress = progress
                    }
                }
            }
        })
        // 타이머 실행
        timer.fire()
        // 플레이어 이미지 설정
        let image = player.isPlaying ? UIImage(named: "icon_pause") : UIImage(named: "icon_play")
        playButton.setImage(image, for: .normal)
    }
    
    @IBAction func touchedPlayButton(_ sender: UIButton) {
        print("player status -> \(player.isPlaying)")
        // 아이콘 표시
        let image = player.isPlaying ? UIImage(named: "icon_play") : UIImage(named: "icon_pause")
        sender.setImage(image, for: .normal)
        if player.isPlaying {
            player.pause()
        } else {
            musicPlay(music: data_item[selectIndex])
        }
    }
    
    func musicPlay(music: URL) {
        // 실행되고 있으면 중단
        if player.isPlaying { player.stop() }
        print("musicPlay \(music)")
        if let name = music.absoluteString.split(separator: "/").last?.split(separator: ".").first {
            do {
                let audio_file = try AVAudioFile(forReading: music)
                sourceFile = audio_file
                format = audio_file.processingFormat
                player.scheduleFile(audio_file, at: nil, completionHandler: {
                    print("\(name) completed")
                    DispatchQueue.main.async {
                        // 프로그레스바 초기화
                        self.playProgressView.progress = 0.0
                        // 다음 곡 설정
                        self.selectIndex += 1
                        if self.selectIndex >= self.data_item.count { self.selectIndex = 0 }
                        // 다음 곡 재생
                        self.musicPlay(music: self.data_item[self.selectIndex])
                        // 현재 재생 중인 테이블 뷰의 셀을 표시하기
                        self.fileListTableView.selectRow(at: IndexPath(row: self.selectIndex, section: 0), animated: false, scrollPosition: .none)
                    }
                })
                playTitleLabel.text = String(name)
                setupRemoteCommand(title: String(name), current: player.current, duration: audio_file.duration, rate: player.rate)
                player.play()
            } catch { print("AVAudioFile error -> \(error.localizedDescription)") }
        }
    }
    
    func hasHeadphones(in routeDescription: AVAudioSessionRouteDescription) -> Bool {
        print("Filter the outputs to only those with a port type of headphones.")
        return !routeDescription.outputs.filter({$0.portType == .headphones}).isEmpty
    }
    
    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }
        print("Switch over the interruption type. \(type)")
        switch type {
        case .began:
            print("An interruption began. Update the UI as needed.")
            self.player.pause()
        case .ended:
            print("An interruption ended. Resume playback, if appropriate.")
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                print("Interruption ended. Playback should resume.")
                self.player.play()
            } else {
                print("Interruption ended. Playback should not resume.")
            }
        default: ()
        }
    }

    @objc func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
                return
        }
        print("Switch over the route change reason.")
        var headphonesConnected = false
        switch reason {
        case .newDeviceAvailable:
            print("New device found.")
            let session = AVAudioSession.sharedInstance()
            headphonesConnected = hasHeadphones(in: session.currentRoute)
        case .oldDeviceUnavailable:
            print("Old device removed.")
            if let previousRoute =
                userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
                headphonesConnected = hasHeadphones(in: previousRoute)
            }
        default: ()
        }
        print("headphonesConnected \(headphonesConnected)")
    }
    
}

extension MainViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 선택된 인덱스 저장
        selectIndex = indexPath.row
        // 선택된 음원 플레이
        musicPlay(music: data_item[selectIndex])
        // 0.5초후에 플레이
        DispatchQueue.main.asyncAfter(deadline: .now() + .microseconds(300)) {
            self.playButton.setImage(UIImage(named: "icon_pause"), for: .normal)
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        print("canMoveRowAt")
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        print("moveRowAt")
        let tmp = data_item[sourceIndexPath.row]
        data_item.remove(at: sourceIndexPath.row)
        data_item.insert(tmp, at: destinationIndexPath.row)
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

extension MainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data_item.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fileCell", for: indexPath) as! FileListCell
        if let name = data_item[indexPath.row].absoluteString.split(separator: "/").last?.split(separator: ".").first {
            cell.fileTitleLabel.text = String(name)
        }
        return cell
    }
}

extension MainViewController: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning dragSession: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        print("itemsForBeginning")
        let music = self.data_item[indexPath.row]
        let itemProvider = NSItemProvider(object: music as NSItemProviderWriting)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        return [dragItem]
    }
    
}

extension MainViewController: UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        //print("dropSessionDidUpdate")
        // 움직일때마다 이걸 탄다, 좌표마다 타는 것 같음
        return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        print("performDropWith")
        // 확인해보니 현재 이곳을 타지 않는다.
    }
}
