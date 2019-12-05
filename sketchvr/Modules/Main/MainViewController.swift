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
import MetalScope

class MainViewController: UIViewController {
    
    @IBOutlet weak var label: UILabel!
    
    private lazy var control: ControlService = ServiceLocator.inject()
    private lazy var apiDriver: ApiDriver = ServiceLocator.inject()
    
    lazy var device: MTLDevice = {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Failed to create MTLDevice")
        }
        return device
    }()

    weak var panoramaView: PanoramaView?
    
    private var observers: [Any]?
    
    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    private func loadPanoramaView() {
        let panoramaView = PanoramaView(frame: view.bounds, device: device)
        panoramaView.setNeedsResetRotation()
        panoramaView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(panoramaView)
        
        // fill parent view
        let constraints: [NSLayoutConstraint] = [
            panoramaView.topAnchor.constraint(equalTo: view.topAnchor),
            panoramaView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            panoramaView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            panoramaView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
        
        // double tap to reset rotation
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTapAction(_:)))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        panoramaView.addGestureRecognizer(doubleTapGestureRecognizer)

        self.panoramaView = panoramaView
        
        panoramaView.load(UIImage(imageLiteralResourceName: "screenshot-hello!-1574677627798"), format: .stereoOverUnder)
            
//            self.observer = NotificationCenter.default.addObserver(forName: .onSelectedSkin, object: nil, queue: notificationQueue) { (notification) in
//                guard let node = notification.userInfo?["obj"] as? SCNNode else { return }
//
//    //            guard self.lastSend.timeIntervalSinceNow < -0.5 else { return }
//    //            self.lastSend = Date()
//
//                let q: SCNQuaternion = node.worldOrientation
//    //            node.worl
//    //
//                let event: JSON = ["event" : "orientation",
//                                   "quaternion": [
//                                    q.x,
//                                    q.y,
//                                    q.z,
//                                    q.w
//                    ]]
//                self.socket.write(string: event.rawString()!)
//    //            print(node.worldOrientation)
//            }
        }
    
    
    var o: Any!
    override func viewDidLoad() {
        super.viewDidLoad()
        
          loadPanoramaView()
//        apiDriver.connect(to: URL(string: "ws://10.19.140.153:8082/")!)
        apiDriver.connect(to: URL(string: "ws://192.168.1.176:8082/")!)
            .then(on: .main) {
                print("connected")
        }
        .catch { error in
            print("ApiDriver error \(error)")
        }
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//            self.webView.callAction(.load)
//        }
    
//        let o = NotificationCenter.default.addObserver(forName: .onSelectedSkin, object: nil, queue: .main) { [weak self] (_) in
//            self?.webView.callAction(.load)
//        }
//        let f = NotificationCenter.default.addObserver(forName: .onStepForws, object: nil, queue: .main) { [weak self] (_) in
//            self?.webView.callAction(.stepForward)
//        }
//
//        self.o = [o, f]
        
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

//        fileManager.downloadWebApp(forced: refresh).then { dirURL -> URL in
//            try self.locahost.serveLocalhost(from: dirURL, publicUrl: self.fileManager.cloudUrl)
//        }
//        .then { localhostURL -> Void in
////            self.webView.load(URLRequest(url: localhostURL))
//        }
//        .then {
//            hud.dismiss()
//        }
//        .catch { error in
//            hud.indicatorView = JGProgressHUDErrorIndicatorView()
//            hud.textLabel.text = error.localizedDescription
//            hud.dismiss(afterDelay: 5, animated: true)
//        }
    }
    
    @IBAction private func forwardActionBtn(_ sender: Any) {
//        webView.callAction(.stepForward)
    }
    
    @IBAction private func backwardActionBtn(_ sender: Any) {
//        webView.callAction(.stepBack)
    }
    
    @IBAction private func loadActionBtn(_ sender: Any) {
//        webView.callAction(.load)
    }
    
    @objc func doubleTapAction(_ sender: Any) {
        panoramaView?.setNeedsResetRotation()
    }
   
    
}




