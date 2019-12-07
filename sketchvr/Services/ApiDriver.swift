//
//  ApiDriver.swift
//  sketchvr
//
//  Created by Hubert Andrzejewski on 01/12/2019.
//  Copyright © 2019 Hubert Andrzejewski. All rights reserved.
//

import Foundation
import Starscream
import Promises

final class ApiDriver: NSObject, WebSocketDelegate {
    
    enum ApiDriverError: Error {
        case notConfigured
        case connection(_ error: Error?)
        case userCancelled
    }
    
    @objc enum State: Int, RawRepresentable {
        case disconnected
        case connecting
        case connected
    }
    
    private var serverUrl: URL?
    private var websocket: WebSocket?
    private lazy var queue = DispatchQueue(label: "com.antrov.sketchvr.startscream")
    private var connectionPromise: Promise<Void>?
    
    @objc dynamic
    private(set) var state: State = .disconnected
     
    func connect(to address: URL) -> Promise<Void> {
        guard connectionPromise == nil || serverUrl != address else { return connectionPromise! }
        
        connectionPromise?.reject(ApiDriverError.userCancelled)
        
        if serverUrl != address {
            serverUrl = address
            websocket = setupSocket(with: address)
        }
        
        return connectSocketWithRetrying(with: address)
    }
    
    private func setupSocket(with url: URL) -> WebSocket {
        websocket?.delegate = nil
        websocket?.disconnect()
        
        let socket = WebSocket(url: url)
        socket.delegate = self
        socket.callbackQueue = queue
        
        return socket
    }
    
    private func connectSocket() -> Promise<Void> {
        guard let socket = websocket else { return Promise<Void>(ApiDriverError.notConfigured) }
        
        state = .connecting
        connectionPromise = Promise<Void>.pending()
            
        connectionPromise?
            .then { [weak self] in
                self?.state = .connected
            }
            .catch { [weak self] _ in
                self?.state = .disconnected
            }
        
        socket.connect()
        
        return connectionPromise!
    }
    
    private func connectSocketWithRetrying(with url: URL) -> Promise<Void> {
        return retry(on: queue,
                     attempts: .max,
                     delay: 10,
                     condition: { [weak self] (_, _) -> Bool in self?.serverUrl == url }) {
                        self.connectSocket()
        }
        .always { [weak self] in
            self?.connectionPromise = nil
        }
    }
    
    // MARK: <WebSocketDelegate>
    
    func websocketDidConnect(socket: WebSocketClient) {
        connectionPromise?.fulfill(())
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        connectionPromise?.reject(ApiDriverError.connection(error))
        
        guard connectionPromise == nil, let url = serverUrl else { return }
        _ = connectSocketWithRetrying(with: url)
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        print("got some text: \(text)")
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        
    }
}
