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

final class ApiDriver: WebSocketDelegate {
    
    private var serverUrl: URL?
    private var websocket: WebSocket?
    private lazy var queue = DispatchQueue(label: "com.antrov.sketchvr.startscream")
    private var connectionPromise: Promise<Void>?
     
    func connect(to address: URL) -> Promise<Void> {
        guard connectionPromise == nil || serverUrl != address else { return connectionPromise! }
        
        connectionPromise?.reject(PromiseError.timedOut)
        
        websocket?.delegate = nil
        websocket?.disconnect()
        
        let socket = WebSocket(url: address)
        socket.delegate = self
        socket.callbackQueue = queue
        
        serverUrl = address
        websocket = socket
        
        return retry(on: queue,
                     attempts: .max,
                     delay: 10,
                     condition: { [weak self] (_, _) -> Bool in self?.serverUrl == address }) {
                        print("retrying")
                        return self.connect()
        }
        .always { [weak self] in
            self?.connectionPromise = nil
            print("connection promise set to nil")
        }
    }
    
    private func connect() -> Promise<Void> {
        guard let socket = websocket else { return Promise<Void>(PromiseError.timedOut) }
        
        socket.connect()
        connectionPromise = Promise<Void>.pending().always {
            print("connection prlmise finished")
        }
        
        return connectionPromise!
    }
    
    // MARK: <WebSocketDelegate>
    
    func websocketDidConnect(socket: WebSocketClient) {
        print("websocket is connected")
        connectionPromise?.fulfill(())
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("websocket is disconnected: \(error?.localizedDescription ?? "")")
        connectionPromise?.reject(PromiseError.timedOut)
        
        guard connectionPromise == nil, let url = serverUrl else { return }
        connect(to: url)
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        print("got some text: \(text)")
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        
    }
}
