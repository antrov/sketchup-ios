//
//  MainViewController.swift
//  sketchvr
//
//  Created by Hubert Andrzejewski on 18/11/2019.
//  Copyright © 2019 Hubert Andrzejewski. All rights reserved.
//

import UIKit
import WebKit
import MediaPlayer

class MainViewController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var label: UILabel!
    
    private lazy var player = AVQueuePlayer()
    private var playerLooper: AVPlayerLooper?
    private var playerItem: AVPlayerItem?
    
    private var observers: [Any]?
    
    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        let date = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: date, completionHandler:{ })
        
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.uiDelegate = self
        webView.navigationDelegate = self
        //        webView.load(URLRequest(url: URL(string: "https://autumn-bayberry.glitch.me/")!))
        webView.load(URLRequest(url: URL(string: "https://192.168.1.176:8080/")!))
        
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(true, options: [])
            let volumeToken = session.observe(\AVAudioSession.outputVolume, options: [.new, .old], changeHandler: volumeDidChange)
            
            self.observers = [volumeToken]
        } catch {
            print(errno)
        }
        
        MPVolumeView.setVolume(0.5)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupRemoteTransportControls()
        
        guard let path = Bundle.main.path(forResource: "acdc", ofType: "mp3"), let url =  URL(string: path) else { fatalError() }
        
        playerItem = AVPlayerItem(url: url)
        playerLooper = AVPlayerLooper(player: player, templateItem: playerItem!)
        
        player.play()
        setupNowPlaying()
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?){
        guard motion == .motionShake else { return }
        print("Shake Gesture Detected")
        webView.reload()
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
        self.label.text = "\(Date())"
        webView.evaluateJavaScript("stepCamera();", completionHandler: nil)
        return .success
    }
    
    private func volumeDidChange(_ session: AVAudioSession, _ change: NSKeyValueObservedChange<Float>) {
        guard let newValue = change.newValue, newValue != 0.5 else { return }
        
        //      let volume = notification.userInfo!["AVSystemController_AudioVolumeNotificationParameter"] as! Float
        //
//        print(newValue - oldValue)
        MPVolumeView.setVolume(0.5)
    }
    
}

extension MainViewController: WKUIDelegate {
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: message,message: nil,preferredStyle:
            .alert)
        
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel) {_ in
            completionHandler()})
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: message,message: nil,preferredStyle:
            .alert)
        
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel) {_ in
            completionHandler(true)})
        
        self.present(alertController, animated: true, completion: nil)
    }
    
}

extension MainViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential,  URLCredential(trust: challenge.protectionSpace.serverTrust!))
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


