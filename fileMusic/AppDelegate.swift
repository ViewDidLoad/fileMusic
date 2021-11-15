//
//  AppDelegate.swift
//  fileMusic
//
//  Created by viewdidload soft on 2020/03/05.
//  Copyright © 2020 viewdidload soft. All rights reserved.
//

import UIKit
import AVFoundation
import GoogleMobileAds
import PythonSupport

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var audioSessionObserver: Any?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        //print("didFinishLaunchingWithOptions")
        // Observe AVAudioSession notifications.
        // Note that a real app might need to observe other AVAudioSession notifications, too,
        // especially if it needs to properlay handle playback interruptions when the app is in the background.
        let notificationCenter = NotificationCenter.default
        audioSessionObserver = notificationCenter.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: nil) { [unowned self] _ in
            self.setUpAudioSession()
        }
        // configure the audio session initially
        setUpAudioSession()
        
        // 데이터베이스 생성은 한번만 해야 함.
        let db = DBHelper()
        let uuid = UserDefaults.standard.string(forKey: "uuid")
        if uuid == nil {
            UserDefaults.standard.set(UUID().uuidString, forKey: "uuid")
            UserDefaults.standard.set(10, forKey: "elixir")
            // 데이터베이스 생성해야 함.
            db.createTable()
        }
        
        // 구글 애드몹 설정
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        // 테스트 모드 기기 등록, 내 아이폰 테스트 기기 설정
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [ "bae5161289c9cb3b73b84388355350e8" ]
        // 백그라운드 사운드 컨트롤
        //application.beginReceivingRemoteControlEvents()
        // 백그라운드 재생
        /*
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback)
            // 이렇게 하니까 다른 앱에서 실행해도 음원은 중지 되지 않는다. 하지만 인터럽트 이벤트가 안온다.
            //try audioSession.setCategory(.playback, options: .mixWithOthers)
            do {
                try audioSession.setActive(true)
            } catch { print("audioSession.setActive error") }
        } catch { print("audioSession.setCategory error") }
        //
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: AVAudioSession.RouteSharingPolicy.longFormAudio)
        } catch {
            print("Failed to set audio session route sharing policy: \(error)")
        }
        // */
        // Youtube-dl
        PythonSupport.initialize()
        
        return true
    }

    // A helper method that configures the app's audio session.
    // Note that the `.longForm` policy indicates that the app's audio output should use AirPlay 2
    // for playback.
    /// - Tag: LongForm
    private func setUpAudioSession() {
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: AVAudioSession.RouteSharingPolicy.longFormAudio)
        } catch {
            print("Failed to set audio session route sharing policy: \(error)")
        }
    }
    
    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        //print("configurationForConnecting")
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        //print("didDiscardSceneSessions")
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

