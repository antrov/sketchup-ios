//
//  MainViewController.swift
//  sketchvr
//
//  Created by Hubert Andrzejewski on 18/11/2019.
//  Copyright © 2019 Hubert Andrzejewski. All rights reserved.
//

import UIKit
import Promises
import JGProgressHUD

class MainViewController: UIViewController {
    
    @IBOutlet weak var webView: VRWebView!
    @IBOutlet weak var label: UILabel!
    
    private lazy var control: ControlService = ServiceLocator.inject()
    private lazy var fileManager: RemoteFilesManager = ServiceLocator.inject()
    private lazy var locahost: LocalhostService = ServiceLocator.inject()
    
    private var observers: [Any]?
    
    override func becomeFirstResponder() -> Bool {
        return true
    }
    var o: Any!
    override func viewDidLoad() {
        super.viewDidLoad()
       
        setupWebApp()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.webView.callAction(.load)
        }
    
        let o = NotificationCenter.default.addObserver(forName: .onSelectedSkin, object: nil, queue: .main) { [weak self] (_) in
            self?.webView.callAction(.load)
        }
        let f = NotificationCenter.default.addObserver(forName: .onStepForws, object: nil, queue: .main) { [weak self] (_) in
            self?.webView.callAction(.stepForward)
        }
        
        self.o = [o, f]
        
        control.start()
       
//        webView.load(URLRequest(url: URL(string: "https://autumn-bayberry.glitch.me/")!))
//        webView.load(URLRequest(url: URL(string: "http://127.0.0.1:8080/")!))
//        webView.load(URLRequest(url: URL(string: "https://192.168.1.231:8080/")!))
//        webView.load(URLRequest(url: URL(string: "https://raw.githubusercontent.com/end3r/MDN-Games-3D/gh-pages/A-Frame/shapes.html")!))
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?){
        guard motion == .motionShake else { return }
        setupWebApp(refresh: true)
    }
    
    private func setupWebApp(refresh: Bool = false) {
        let hud = JGProgressHUD(style: .dark)
        
        hud.textLabel.text = "Downloading"
        hud.show(in: self.view)

        fileManager.downloadWebApp(forced: refresh).then { dirURL -> URL in
            try self.locahost.serveLocalhost(from: dirURL, publicUrl: self.fileManager.cloudUrl)
        }
        .then { localhostURL -> Void in
            self.webView.load(URLRequest(url: localhostURL))
        }
        .then {
            hud.dismiss()
        }
        .catch { error in
            hud.indicatorView = JGProgressHUDErrorIndicatorView()
            hud.textLabel.text = error.localizedDescription
            hud.dismiss(afterDelay: 5, animated: true)
        }
    }
    
    @IBAction private func forwardActionBtn(_ sender: Any) {
        webView.callAction(.stepForward)
    }
    
    @IBAction private func backwardActionBtn(_ sender: Any) {
        webView.callAction(.stepBack)
    }
    
    @IBAction private func loadActionBtn(_ sender: Any) {
        webView.callAction(.load)
    }
    
   
    
}




