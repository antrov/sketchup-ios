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
import SceneKit
import QRCodeReader

class MainViewController: UIViewController, QRCodeReaderViewControllerDelegate, ApiDriverDelegate, ControlServiceDelegate, SphereViewDelegate {
    
    private struct UserDefaultsKeys {
        private init() {}
        
        static let lastApiURL = "com.antrov.lastApiURL"
    }
    
    @IBOutlet weak var sphereView: SphereView!
    @IBOutlet weak var sphereModeBtn: UIButton!
    @IBOutlet weak var buttonsView: UIView!
    
    private lazy var control: ControlService = ServiceLocator.inject()
    private lazy var apiDriver: ApiDriver = ServiceLocator.inject()
    private var quaternionTimer: Timer?
    
    private func connectApi(at url: URL) {
        let hud = JGProgressHUD(style: .dark)
        hud.textLabel.text = url.absoluteString
        hud.show(in: view)
        
        apiDriver.connect(to: url)
        .then(on: .main) {
            hud.dismiss()
            self.apiDriver.request(action: ApiAction(.screenshot))
            UserDefaults.standard.set(url, forKey: UserDefaultsKeys.lastApiURL)
        }
        .catch { error in
            hud.indicatorView = JGProgressHUDErrorIndicatorView()
            hud.textLabel.text = error.localizedDescription
            hud.dismiss(afterDelay: 5)
        }
    }
    
    private func requestStep(forward: Bool) {
        guard let q = sphereView.quaternion else { return }
        let action = ApiAction(step: forward ? .stepForward : .stepBackward, quaternion: [q.x, q.y, q.z, q.w])
        
        _ = apiDriver.request(action: action)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        apiDriver.delegate = self
        control.delegate = self
        sphereView.delegate = self
        
        guard let lastApiURL = UserDefaults.standard.url(forKey: UserDefaultsKeys.lastApiURL) else { return }
        connectApi(at: lastApiURL)
    }
    
    @IBAction private func forwardActionBtn(_ sender: Any) {
        requestStep(forward: true)
    }
    
    @IBAction private func backwardActionBtn(_ sender: Any) {
        requestStep(forward: false)
    }
    
    @IBAction private func qrActionBtn(_ sender: Any) {
        let reader = QRCodeReaderViewController(builder: QRCodeReaderViewControllerBuilder { builder in
            builder.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
            builder.showSwitchCameraButton = false
        })
        
        reader.delegate = self
        reader.modalPresentationStyle = .formSheet
        
        present(reader, animated: true, completion: nil)
    }
    
    @IBAction private func toggleLiveQuaternionAction(_ sender: Any) {
        guard let button = sender as? UIButton else { return }
        
        if quaternionTimer != nil {
            quaternionTimer?.invalidate()
            quaternionTimer = nil
        } else {
            quaternionTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { (_) in
                guard let q = self.sphereView.quaternion else { return }
                let action = ApiAction(step: .quaternion, quaternion: [q.x, q.y, q.z, q.w])
                
                _ = self.apiDriver.request(action: action)
            })
        }
        
        button.isSelected = quaternionTimer != nil
    }
    
    private func toggleSphereMode() {
        _ = sphereView.toggleMode()
        sphereModeBtn.isSelected = sphereView.mode == .stereo
    }
    
    @IBAction private func togglePresenterMode(_ sender: Any) {
        toggleSphereMode()
        _ = apiDriver.request(action: ApiAction(.screenshot))
    }
   
    @IBAction func doubleTapAction(_ sender: Any) {
        sphereView.resetRotation()
    }
    
    // MARK: <QRCodeReaderViewControllerDelegate>
    
    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        reader.stopScanning()
        dismiss(animated: true, completion: nil)
        
        guard let apiUrl = URL(string: result.value) else { return }
        connectApi(at: apiUrl)
    }
    
    func readerDidCancel(_ reader: QRCodeReaderViewController) {
      reader.stopScanning()
      dismiss(animated: true, completion: nil)
    }
    
    // MARK: <ApiDriverDelegate>
    
    func apiDriverDidReceiveScreenshot(_ data: Data) {
        guard let image = UIImage(data: data) else { return }
        
        if sphereView.mode == .empty {
            sphereView.mode = .panorama
            control.start()
        }
        
//        let size = CGSize(width: image.size.width, height: image.size.height * 2)
//        let areaSize = CGRect(origin: .zero, size: size)
//
//        UIGraphicsBeginImageContext(size)
//
//        image.draw(in: areaSize)
//        image.draw(in: areaSize.offsetBy(dx: 0, dy: image.size.height))
//
//        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
//
//        UIGraphicsEndImageContext()
        
        sphereView.load(image: image)
    }
    
    // MARK: <ControlServiceDelegate>
    
    func controlServiceDidReceive(event: ControlService.ControlEvent) {
        switch event {
        case .up:
            requestStep(forward: true)
            
        case .down:
            requestStep(forward: false)
        }
    }
    
    // MARK: <SphereViewDelegate>
    
    func sphereViewDidTap() {
        requestStep(forward: true)
    }
    
    func sphereViewDidDoubleTap() {
        toggleSphereMode()
        buttonsView.isHidden = sphereView.mode == .stereo
    }
    
}




