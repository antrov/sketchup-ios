//
//  VRWebView.swift
//  sketchvr
//
//  Created by Hubert Andrzejewski on 18/11/2019.
//  Copyright © 2019 Hubert Andrzejewski. All rights reserved.
//

import UIKit
import WebKit

final class VRWebView: WKWebView, WKUIDelegate, WKNavigationDelegate {
    
    enum Action: String {
        case stepForward
        case stepBack
        case resetPosition
        case interact
        case loadModel
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.isScrollEnabled = false
        
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.allowsInlineMediaPlayback = true
        
        uiDelegate = self
        navigationDelegate = self
        
//        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
//        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: Date.distantPast, completionHandler:{ })
    }
    
    func callAction(_ action: Action) {
        
    }
    
    // MARK: <WKUIDelegate>       
    
    // MARK: <WKNavigationDelegate>
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        print(navigationResponse)
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential,  URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}
