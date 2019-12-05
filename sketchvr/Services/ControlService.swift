//
//  ControlService.swift
//  sketchvr
//
//  Created by Hubert Andrzejewski on 18/11/2019.
//  Copyright © 2019 Hubert Andrzejewski. All rights reserved.
//

import Foundation
import MediaPlayer


final class ControlService {
    
//    static let
    // https://www.raywenderlich.com/835-audiokit-tutorial-getting-started
    
    private lazy var player = AVQueuePlayer()
    private var playerLooper: AVPlayerLooper?
    private var playerItem: AVPlayerItem?
    
    private var observers: [Any]?
    
    func start() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(true, options: [])
            let volumeToken = session.observe(\AVAudioSession.outputVolume, options: [.new, .old], changeHandler: volumeDidChange)
            
            self.observers = [volumeToken]
        } catch {
            print(errno)
        }
        
        MPVolumeView.setVolume(0.5)
        setupRemoteTransportControls()
        
        
        //        guard let path = Bundle.main.path(forResource: "acdc", ofType: "mp3"), let url =  URL(string: path) else { fatalError() }
        //
        //        playerItem = AVPlayerItem(url: url)
        //        playerLooper = AVPlayerLooper(player: player, templateItem: playerItem!)
        //
        //        player.play()
        //        setupNowPlaying()
    }
    
    private func volumeDidChange(_ session: AVAudioSession, _ change: NSKeyValueObservedChange<Float>) {
        guard let newValue = change.newValue, newValue != 0.5 else { return }
        
        //      let volume = notification.userInfo!["AVSystemController_AudioVolumeNotificationParameter"] as! Float
        //
        //        print(newValue - oldValue)
        MPVolumeView.setVolume(0.5)
//        NotificationCenter.default.post(name: .onStepForws, object: nil, userInfo: nil)
    }
    
    func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.isEnabled = false
        commandCenter.pauseCommand.isEnabled = false
        commandCenter.togglePlayPauseCommand.isEnabled = true
        
        commandCenter.playCommand.addTarget(handler: self.remoteEventReceived(_:))
        commandCenter.pauseCommand.addTarget(handler: self.remoteEventReceived(_:))
        commandCenter.togglePlayPauseCommand.addTarget(handler: self.remoteEventReceived(_:))
    }
    
    func setupNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [MPMediaItemPropertyTitle: "sketchup"]
    }
    
    func remoteEventReceived(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        print("remote")
        //        self.label.text = "\(Date())"
        //        webView.evaluateJavaScript("stepCamera();", completionHandler: nil)
        return .success
    }
    
}

extension MPVolumeView {
    static func setVolume(_ volume: Float) {
        let volumeView = MPVolumeView()
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = volume
        }
    }
}
