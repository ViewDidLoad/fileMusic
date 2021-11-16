//
//  MainViewController.swift
//  fileMusic
//
//  Created by viewdidload soft on 2020/09/15.
//  Copyright © 2020 viewdidload soft. All rights reserved.
//

import UIKit
import SwiftUI
import AVKit
import CoreMedia
import AVFoundation
import MediaPlayer
import GoogleMobileAds
import AppTrackingTransparency
import AdSupport

class FileListCell: UITableViewCell {
    @IBOutlet weak var fileTitleLabel: UILabel!
}

class MainViewController: UIViewController, RemoteCommandHandler {
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var nickLabel: UILabel!
    @IBOutlet weak var elixirButton: UIButton!
    @IBOutlet weak var elixirLabel: UILabel!
    @IBOutlet weak var configButton: UIButton!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var playView: UIView!
    @IBOutlet weak var playTitleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var prevButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var tileSlider: UISlider!
    @IBOutlet weak var listView: UIView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var fileListTableView: UITableView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var bottomViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var youtubeDlButton: UIButton!
    
    // 플레이 파일 목록
    let fm = FileManager.default
    var docuPath = ""
    // 마법물약
    var elixir_count = 0
    // 구글 애드몹 광고창
    var bannerView = GADBannerView()
    // 신규
    var originalItems: [PlaylistItem] = []
    let sampleBufferPlayer = SampleBufferPlayer()
    let initialItem = ["Blumenlied", "Canon"]
    // Private notification observers.
    private var currentOffsetObserver: NSObjectProtocol!
    private var currentItemObserver: NSObjectProtocol!
    private var playbackRateObserver: NSObjectProtocol!
    // 'true' when the time offset slider is being dragged.
    private var isDraggingOffset: Bool = false
    
    override func viewDidLoad() {
        //print("MainViewController.viewDidLoad")
        super.viewDidLoad()
        // 파일 설정 -> 리스트에 url을 넣자 기본 도큐먼트 내부에 fileMusic 폴더를 기본으로 설정
        docuPath = fm.urls(for: .documentDirectory, in: .userDomainMask).first!.path.appending("fileMusic")
        // topView
        topView.layer.cornerRadius = 15.0
        topView.layer.borderWidth = 1.0
        topView.layer.borderColor = UIColor.white.cgColor
        // 별명 가져와서 표시
        nickLabel.text = getNick()
        // 마법 물약 개수 가져와서 표기
        //UserDefaults.standard.set(100, forKey: "elixir")
        elixir_count = UserDefaults.standard.integer(forKey: "elixir")
        elixirLabel.text = "\(elixir_count)"
        // playView
        playView.layer.cornerRadius = 15.0
        playView.layer.borderWidth = 1.0
        playView.layer.borderColor = UIColor.white.cgColor
        tileSlider.addTarget(self, action: #selector(onSliderValChanged(slider:event:)), for: .valueChanged)
        // listView
        listView.layer.cornerRadius = 15.0
        listView.layer.borderWidth = 1.0
        listView.layer.borderColor = UIColor.white.cgColor
        editButton.layer.cornerRadius = 5.0
        editButton.layer.borderWidth = 1.0
        editButton.layer.borderColor = UIColor.white.cgColor
        doneButton.layer.cornerRadius = 5.0
        doneButton.layer.borderWidth = 1.0
        doneButton.layer.borderColor = UIColor.white.cgColor
        fileListTableView.delegate = self
        fileListTableView.dataSource = self
        fileListTableView.rowHeight = UITableView.automaticDimension
        // 신규 추가됨.
        fileListTableView.allowsSelectionDuringEditing = false
        // youtubeDL button
        youtubeDlButton.layer.cornerRadius = 15.0
        youtubeDlButton.layer.borderWidth = 1.0
        youtubeDlButton.layer.borderColor = UIColor.white.cgColor
        youtubeDlButton.isHidden = true
        // Observe various notifications.
        let notificationCenter = NotificationCenter.default
        currentOffsetObserver = notificationCenter.addObserver(forName: SampleBufferPlayer.currentOffsetDidChange, object: sampleBufferPlayer, queue: .main) { [unowned self] notification in
            let offset = (notification.userInfo? [SampleBufferPlayer.currentOffsetKey] as? NSValue)?.timeValue.seconds
            self.updateOffsetLabel(offset)
        }
        currentItemObserver = notificationCenter.addObserver(forName: SampleBufferPlayer.currentItemDidChange, object: sampleBufferPlayer, queue: .main) { [unowned self] _ in
            self.updateCurrentItemInfo()
        }
        playbackRateObserver = notificationCenter.addObserver(forName: SampleBufferPlayer.playbackRateDidChange, object: sampleBufferPlayer, queue: .main) { [unowned self] _ in
            self.updatePlayPauseButton()
            self.updateCurrentPlaybackInfo()
        }
        // Configure the view's controls.
        doneButton.alpha = 0
        updateOffsetLabel(0)
        updatePlayPauseButton()
        // Start using the Now Playing Info panel.
        RemoteCommandCenter.handleRemoteCommands(using: self)
        // Configure now-playing info initially.
        updateCurrentItemInfo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //print("MainViewController.viewWillAppear")
        // 바닥 뷰의 크기를 0으로 설정하여 나오지 않도록 하고 광고 데이터 받았을 때 나오도록 함
        bottomViewHeightConstraint.constant = 8.0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updatePlaylist()
        /*/ 디렉토리의 파일을 가져온다
        updateFileList()
        // 가져올 파일이 없으면 샘플 파일을 로딩
        if data_item.count == 0 {
            if let fileUrl_1 = Bundle.main.url(forResource: "Blumenlied", withExtension: "mp3") {
                data_item.append(fileUrl_1)
                isSampleMusic = true
            }
            if let fileUrl_2 = Bundle.main.url(forResource: "Canon", withExtension: "mp3") {
                data_item.append(fileUrl_2)
                isSampleMusic = true
            }
            DispatchQueue.main.async {
                self.fileListTableView.reloadData()
            }
        }
        // */
        // 애드몹 광고창 설정
        let adSize = getFullWidthAdaptiveAdSize(view: bottomView)
        bannerView = GADBannerView(adSize: adSize, origin: CGPoint.zero)
        bannerView.adUnitID = "ca-app-pub-7335522539377881/7377884882"
        bannerView.rootViewController = self
        bannerView.delegate = self
        bottomView.addSubview(bannerView)
        let adEnable = UserDefaults.standard.bool(forKey: "AdEnable")
        //*/ 스크린 샷을 위해 광고 중지
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { (status) in
                if adEnable {
                    self.bannerView.load(GADRequest())
                }
            }
        } else {
            if adEnable {
                bannerView.load(GADRequest())
            }
        }
        // */
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        //print("MainViewController.viewDidDisappear")
        super.viewDidDisappear(animated)
    }
    
    @IBAction func elixirButtonTouched(_ sender: UIButton) {
        if elixir_count > 0 {
            // 광고 설정이 되었을 때만 버튼 보여준다.
            let ad = UserDefaults.standard.bool(forKey: "AdEnable")
            if ad == true {
                // 엘릭샤 카운트 감소
                elixir_count -= 1
                // 유튜브 다운로드 버튼을 보여준다.
                youtubeDlButton.isHidden = false
            }
            UserDefaults.standard.set(elixir_count, forKey: "elixir")
            elixirLabel.text = "\(elixir_count)"
            // 배너 광고를 제거해준다.
            bannerView.isHidden = true
            // 한번 실행하면 비활성화 하자.
            sender.isEnabled = false
        } else {
            // 설정화면에서 엘릭샤 버튼을 터치하여 전면광고를 시청 한 후 다시 시도하세요.
            let alert = UIAlertController(title: "Elixir tribe", message: "Go to config and touch the elixir button to view the ad and replenish it.", preferredStyle: UIAlertController.Style.alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
                alert.dismiss(animated: false, completion: nil)
            }
            alert.addAction(okAction)
            present(alert, animated: false, completion: nil)
        }
    }
    
    @IBAction func configButtonTouched(_ sender: UIButton) {
        //print("config button touched")
        // 설정 창으로 이동
        let board = UIStoryboard(name: "Main", bundle: nil)
        let vc = board.instantiateViewController(withIdentifier: "configVC") as! ConfigViewController
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .coverVertical
        present(vc, animated: false, completion: nil)
    }
    
    @IBAction func prevButtonTouched(_ sender: UIButton) {
        skipToCurrentItem(offsetBy: -1)
    }
    
    @IBAction func playButtonTouched(_ sender: UIButton) {
        if sampleBufferPlayer.isPlaying {
            sampleBufferPlayer.pause()
        } else {
            sampleBufferPlayer.play()
        }
    }
    
    @IBAction func nextButtonTouched(_ sender: UIButton) {
        skipToCurrentItem(offsetBy: 1)
    }
    
    @IBAction func editButtonTouched(_ sender: UIButton) {
        fileListTableView.setEditing(true, animated: true)
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.3, delay: 0) {
            sender.alpha = 0
            self.doneButton.alpha = 1
        }
    }
    
    @IBAction func doneButtonTouched(_ sender: UIButton) {
        fileListTableView.setEditing(false, animated: true)
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.3, delay: 0) {
            sender.alpha = 0
            self.editButton.alpha = 1
        }
    }
    
    @IBAction func youtubeDLButtonTouched(_ sender: UIButton) {
        /*/ swiftUI 연결, 배포하면 파이썬키트 로딩 안되어서 별도로 리모트 받아서 처리하는 걸로 대체... 나중에 해결되면 연결하자.
        if let swiftUIView = [UIHostingController(rootView: SwiftUIView())].first {
            present(swiftUIView, animated: false, completion: nil)
        }
        // */
        if let swiftUIView = [UIHostingController(rootView: YoutubeDownloadView())].first {
            present(swiftUIView, animated: false, completion: nil)
        }
    }
    
    private func plause() {
        sampleBufferPlayer.pause()
    }
    
    private func play() {
        sampleBufferPlayer.play()
    }
    
    private func nextTrack() {
        skipToCurrentItem(offsetBy: 1)
    }
    
    private func previousTrack() {
        skipToCurrentItem(offsetBy: -1)
    }
    
    private func updatePlaylist() {
        // 현재 파일이 없으면
        if originalItems.count == 0 {
            // 기본 내장된 파일을 일단 document/fileMusic 로 복사하자.
            for i in 0 ..< initialItem.count {
                if let source_url = Bundle.main.url(forResource: initialItem[i], withExtension: "mp3") {
                    var target_url = getDocumentsDirectory().appendingPathComponent("fileMusic", isDirectory: true)
                    // 폴더가 없으면 생성
                    if !FileManager.default.fileExists(atPath: target_url.path) {
                        do {
                            try FileManager.default.createDirectory(at: target_url, withIntermediateDirectories: false, attributes: nil)
                        } catch { print("createOriginalPlaylist createDirectory \(error.localizedDescription)") }
                    }
                    // 각각의 파일을 추가
                    target_url.appendPathComponent("\(initialItem[i])", isDirectory: false)
                    target_url.appendPathExtension("mp3")
                    //print("createOriginalPlaylist source \(source_url.path), target \(target_url.path)")
                    // 파일이 없으면 파일을 복사
                    if !FileManager.default.fileExists(atPath: target_url.path) {
                        do {
                            try FileManager.default.copyItem(at: source_url, to: target_url)
                        } catch { print("createOriginalPlaylist copyitem error \(error.localizedDescription)") }
                    }
                }
            }
        }
        // 혹시나 모르니 일단 비우고
        originalItems.removeAll()
        do {
            // 해당 폴더에서 mp3 파일만 가져와서 리스트에 추가하자.
            let get_url = getDocumentsDirectory().appendingPathComponent("fileMusic", isDirectory: true)
            let items = try FileManager.default.contentsOfDirectory(atPath: get_url.path)
            //print("items count \(items.count)")
            // 세마포어 사용.
            let semaphore = DispatchSemaphore(value: 0)
            for (i, item) in items.enumerated() {
                let filename = "\(get_url.path)/\(item)"
                let fileUrl = URL(fileURLWithPath: filename)
                // item 에서 .mp3 는 제거하자.
                var title = item
                title.removeLast(4)
                //print("fileurl \(fileUrl), \(item), \(title)")
                // 파일 추가
                let asset = AVURLAsset(url: fileUrl)
                asset.loadValuesAsynchronously(forKeys: ["duration"]) {
                    var error: NSError? = nil
                    switch asset.statusOfValue(forKey: "duration", error: &error) {
                    case .loaded:
                        print("loaded \(fileUrl), \(title), \(asset.duration)") // 두개 다 여기를 탄다.
                        self.originalItems.append(PlaylistItem(url: fileUrl, title: title, duration: asset.duration))
                    case .failed where error != nil:
                        //print("failed")
                        self.originalItems.append(PlaylistItem(title: title, error: error!))
                    default:
                        //print("default")
                        let error = NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError)
                        self.originalItems.append(PlaylistItem(title: title, error: error))
                    }
                    // 마지작 아이템에서 세마포어 시작
                    if i == (items.endIndex - 1) { semaphore.signal() }
                }
            }
            semaphore.wait()
            replaceAllItems()
        } catch { print("createOriginalPlaylist Not Found item") }
    }
    
    private func updatePlayPauseButton() {
        if let icon = sampleBufferPlayer.isPlaying ? UIImage(systemName: "pause.fill") : UIImage(systemName: "play.fill") {
            playButton.setImage(icon, for: .normal)
        }
    }

    private func updateOffsetLabel(_ offset: Double?) {
        // During scrubbing, the label represents the slider position instead.
        guard !isDraggingOffset else { return }
        if let currentOffset = offset {
            timeLabel.text = String(format: "%.1f", currentOffset)
            tileSlider.value = Float(currentOffset)
        } else {
            timeLabel.text = ""
            tileSlider.value = 0
        }
    }
    
    private func updateCurrentItemInfo() {
        NowPlayingCenter.handleItemChange(item: sampleBufferPlayer.currentItem, index: sampleBufferPlayer.currentItemIndex ?? 0, count: sampleBufferPlayer.itemCount)
        if let currentItem = sampleBufferPlayer.currentItem {
            let duration = currentItem.duration.seconds
            durationLabel.text = String(format: "%.1f", duration)
            tileSlider.isEnabled = true
            tileSlider.maximumValue = Float(duration)
            playTitleLabel.text = currentItem.title
            updateCurrentPlaybackInfo()
        } else {
            tileSlider.isEnabled = false
            tileSlider.value = 0.0
            timeLabel.text = " "
            playTitleLabel.text = " "
            durationLabel.text = " "
        }
    }
    
    private func updateCurrentPlaybackInfo() {
        NowPlayingCenter.handlePlaybackChange(playing: sampleBufferPlayer.isPlaying, rate: sampleBufferPlayer.rate, position: sampleBufferPlayer.currentItemEndOffset?.seconds ?? 0, duration: sampleBufferPlayer.currentItem?.duration.seconds ?? 0)
    }
    
    func performRemoteCommand(_ command: RemoteCommand) {
        switch command {
        case .pause:
            pause()
        case .play:
            play()
        case .nextTrack:
            nextTrack()
        case .previousTrack:
            previousTrack()
        case .skipForward(let distance):
            skip(by: distance)
        case .skipBackward(let distance):
            skip(by: -distance)
        case .changePlaybackPosition(let offset):
            skip(to: offset)
        }
    }
    
    private func skipToCurrentItem(offsetBy offset: Int) {
        guard let currentItemIndex = sampleBufferPlayer.currentItemIndex,
            sampleBufferPlayer.containsItem(at: currentItemIndex + offset)
            else { return }
        
        sampleBufferPlayer.seekToItem(at: currentItemIndex + offset)
    }
    
    private func skip(to offset: TimeInterval) {
        sampleBufferPlayer.seekToOffset(CMTime(seconds: Double(offset), preferredTimescale: 1000))
        updateCurrentPlaybackInfo()
    }
    
    private func skip(by distance: TimeInterval) {
        guard let offset = sampleBufferPlayer.currentItemEndOffset else { return }
        sampleBufferPlayer.seekToOffset(offset + CMTime(seconds: distance, preferredTimescale: 1000))
        updateCurrentPlaybackInfo()
    }
    
    func hasHeadphones(in routeDescription: AVAudioSessionRouteDescription) -> Bool {
        print("Filter the outputs to only those with a port type of headphones.")
        return !routeDescription.outputs.filter({$0.portType == .headphones}).isEmpty
    }
    
    @objc func onSliderValChanged(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                isDraggingOffset = true
            case .moved:
                timeLabel.text = String(format: "%.1f", tileSlider.value)
            case .ended:
                skip(to: TimeInterval(tileSlider.value))
                isDraggingOffset = false
            default:
                break
            }
        }
    }
    
    /*
    @objc func updateFileList() {
        // 기존 자료 지우고.
        //data_item.removeAll()
        do {
            // 접근한 경로의 디렉토리 내 파일 리스트를 불러옵니다.
            let items = try fm.contentsOfDirectory(atPath: docuPath)
            for item in items {
                let filename = "\(docuPath)/\(item)"
                let fileUrl = URL(fileURLWithPath: filename)
                // filemusic.sqlite 는 제외하자.
                //print("fileurl.lastPathComponent \(fileUrl.lastPathComponent)")
                if fileUrl.lastPathComponent != "filemusic.sqlite" {
                    //data_item.append(fileUrl)
                }
                //isSampleMusic = false
            }
        } catch { print("Not Found item") }
        // 파일 리스트 갱신
        DispatchQueue.main.async {
            self.fileListTableView.reloadData()
            // 배너 창이 보이도록 설정
            self.bannerView.isHidden = false
            // 유튜브 다운로드 감춘다.
            self.youtubeDlButton.isHidden = true
        }
    }
    // */
    
    fileprivate func getFullWidthAdaptiveAdSize(view: UIView) -> GADAdSize {
        let frame = { () -> CGRect in
            if #available(iOS 11.0, *) {
                return view.frame.inset(by: view.safeAreaInsets)
            } else {
                return view.frame
            }
        }()
        return GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(frame.size.width)
    }
    
    private func replaceAllItems() {
        sampleBufferPlayer.replaceItems(with: originalItems)
        fileListTableView.reloadData()
    }
    
    private func replaceItem(at row: Int, with newItem: PlaylistItem) {
        sampleBufferPlayer.replaceItem(at: row, with: newItem)
        fileListTableView.reloadData()
    }
    
    private func removeItem(at row: Int) {
        sampleBufferPlayer.removeItem(at: row)
        fileListTableView.reloadData()
    }
    
    private func moveItem(from sourceRow: Int, to destinationRow: Int) {
        sampleBufferPlayer.moveItem(at: sourceRow, to: destinationRow)
        fileListTableView.reloadData()
    }
    
    private func duplicateItem(at row: Int) {
        let item = sampleBufferPlayer.item(at: row)
        sampleBufferPlayer.insertItem(item, at: sampleBufferPlayer.itemCount)
        fileListTableView.reloadData()
    }
    
}

extension MainViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard sampleBufferPlayer.containsItem(at: indexPath.row) else { return }
        sampleBufferPlayer.seekToItem(at: indexPath.row)
        sampleBufferPlayer.play()
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let duplicateAction = UIContextualAction(style: .normal, title: "Duplicate") { [unowned self] _, _, completionHandler in
            self.duplicateItem(at: indexPath.row)
            completionHandler(true)
        }
        duplicateAction.backgroundColor = UIColor(named: "Duplicate")
        
        let configuration = UISwipeActionsConfiguration(actions: [duplicateAction])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive,title: "Delete") { [unowned self] _, _, completionHandler in
            self.removeItem(at: indexPath.row)
            completionHandler(true)
        }
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let sourceRow = sourceIndexPath.row
        let destinationRow = destinationIndexPath.row
        
        guard sourceRow != destinationRow,
            sampleBufferPlayer.containsItem(at: sourceRow),
            sampleBufferPlayer.containsItem(at: destinationRow) else { return }
        
        moveItem(from: sourceRow, to: destinationRow)
    }
}

extension MainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sampleBufferPlayer.itemCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistCell", for: indexPath) as! FileListCell
        let row = indexPath.row
        let item = sampleBufferPlayer.item(at: row)
        cell.fileTitleLabel.text = item.title
        return cell
    }
}

extension MainViewController: GADBannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        bannerView.alpha = 0.0
        bottomViewHeightConstraint.constant = bannerView.bounds.height
        UIView.animate(withDuration: 0.8) {
            self.view.layoutIfNeeded()
            bannerView.alpha = 1.0
        }
    }
    
    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        print("didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
}
