//
//  MainViewController.swift
//  sketchvr
//
//  Created by Hubert Andrzejewski on 18/11/2019.
//  Copyright © 2019 Hubert Andrzejewski. All rights reserved.
//

import UIKit
import Promises

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        fileManager.downloadWebApp(forced: false).then { dirURL -> URL in
            try self.locahost.serveLocalhost(from: dirURL)
        }
        .then { localhostURL -> Void in
            self.webView.load(URLRequest(url: localhostURL))
        }
        .catch { error in
            print(error)
        }
    
       
//        webView.load(URLRequest(url: URL(string: "https://autumn-bayberry.glitch.me/")!))
//        webView.load(URLRequest(url: URL(string: "http://127.0.0.1:8080/")!))
//        webView.load(URLRequest(url: URL(string: "https://192.168.1.231:8080/")!))
//        webView.load(URLRequest(url: URL(string: "https://raw.githubusercontent.com/end3r/MDN-Games-3D/gh-pages/A-Frame/shapes.html")!))
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?){
        guard motion == .motionShake else { return }
        print("Shake Gesture Detected")
        webView.reload()
    }
    
    
    
   
    
}




