//
//  SphereView.swift
//  sketchvr
//
//  Created by Hubert Andrzejewski on 14/03/2020.
//  Copyright © 2020 Hubert Andrzejewski. All rights reserved.
//

import UIKit
import SceneKit
import MetalScope

protocol SphereViewDelegate: class {
    func sphereViewDidTap()
    func sphereViewDidDoubleTap()
}

class SphereView: UIView {
    
    enum Mode {
        case empty
        case panorama
        case stereo
    }
    
    private weak var panoramaView: PanoramaView?
    private weak var stereoView: StereoView?
    
    private lazy var device: MTLDevice = {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Failed to create MTLDevice")
        }
        return device
    }()
    
    private lazy var doubleTapRecognizer: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTapRecognized(_:)))
        recognizer.numberOfTapsRequired = 2
        return recognizer
    }()
    
    private lazy var tapRecognizer: UITapGestureRecognizer = {
        return UITapGestureRecognizer(target: self, action: #selector(singleTapRecognized(_:)))
    }()
    
    /**
     * Xiaomi Mi VR Play 2
     * Calibarated thanks to http://www.sitesinvr.com/viewer/settings.htm as parameters from offical QR code does not provide sufficient result
     */
    private lazy var stereoParameters: StereoParameters = {
        let parameters = ViewerParameters(lenses: .init(separation: 0.055, offset: 0, alignment: .center, screenDistance: 0.036),
                                          distortion: .init(k1: 0.38, k2: 0),
                                          maximumFieldOfView: .init(outer: 79, inner: 79, upper: 79, lower: 79))
        
        return StereoParameters(screenModel: .default, viewerModel: .custom(parameters: parameters))
    }()
    
    weak var delegate: SphereViewDelegate?
    
    var mode: Mode = .empty {
        didSet {
            guard mode != oldValue else { return }
            loadMetalScope(as: mode)
        }
    }
    
    var quaternion: SCNQuaternion? {
        switch mode {
        case .stereo:
            return stereoView?.orientationNode.pointOfView.worldOrientation
            
        case .panorama:
            return panoramaView?.orientationNode.pointOfView.worldOrientation
            
        default:
            return nil
        }
    }
    
    func toggleMode() -> Mode {
        switch mode {
        case .panorama:
            mode = .stereo
            
        case .stereo,
             .empty:
            mode = .panorama
        }
        
        return mode
    }
    
    func load(image: UIImage) {
        let format: MediaFormat = image.size.width > image.size.height ? .mono : .stereoOverUnder
        
        switch mode {
        case .stereo:
            stereoView?.load(image, format: format)
            
        case .panorama:
            panoramaView?.load(image, format: format)
            
        default:
            return
        }
    }
    
    func resetRotation() {
        switch mode {
        case .stereo:
            stereoView?.setNeedsResetRotation()
            
        case .panorama:
            panoramaView?.setNeedsResetRotation()
            
        default:
            return
        }
    }
    
    private func loadMetalScope(as viewMode: Mode) {
        panoramaView?.removeFromSuperview()
        stereoView?.removeFromSuperview()
        
        var scopeView: UIView!
        
        switch viewMode {
        case .stereo:
            scopeView = StereoView(device: device)
            stereoView = scopeView as? StereoView
            stereoView?.stereoParameters = stereoParameters
            
        case .panorama:
            scopeView = PanoramaView(frame: bounds, device: device)
            panoramaView = scopeView as? PanoramaView
            panoramaView?.antialiasingMode = .multisampling4X
            
        default:
            return
        }
        
        scopeView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scopeView)
        
        let constraints: [NSLayoutConstraint] = [
            scopeView.topAnchor.constraint(equalTo: topAnchor),
            scopeView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scopeView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scopeView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
        
        scopeView.addGestureRecognizer(doubleTapRecognizer)
        scopeView.addGestureRecognizer(tapRecognizer)
    }
    
    
    @objc private func singleTapRecognized(_ sender: Any) {
        delegate?.sphereViewDidTap()
    }
    
    @objc private func doubleTapRecognized(_ sender: Any) {
        delegate?.sphereViewDidDoubleTap()
    }

}
