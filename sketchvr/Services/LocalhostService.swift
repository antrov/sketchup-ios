//
//  LocalhostService.swift
//  sketchvr
//
//  Created by Hubert Andrzejewski on 18/11/2019.
//  Copyright © 2019 Hubert Andrzejewski. All rights reserved.
//

import Foundation
import Swifter

final class LocalhostService: HttpServerIODelegate {
    
    struct RuntimeError: Error {
        let message: String

        init(_ message: String) {
            self.message = message
        }

        public var localizedDescription: String {
            return message
        }
    }
    
    func socketConnectionReceived(_ socket: Socket) {
        print(socket)
    }
    
    private lazy var server: HttpServer = {
        let server = HttpServer()
        server.delegate = self
        return server
    }()
    
    func serveLocalhost(from directory: URL, on port: UInt16 = 8080) throws -> URL {
        server.stop()
        server["/"] = { (request: HttpRequest) -> HttpResponse in
            request.params = ["": ""]
            return shareFilesFromDirectory(directory.path)(request)
        }
        
        try server.start(port, forceIPv4: true, priority: .background)
        
        guard let url = URL(string: "http://127.0.0.1:\(port)/") else { throw RuntimeError("Cannot find socket addr") }
        
        return url
//                let documentDirectory = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
//                let fileURL = documentDirectory//.appendingPathComponent("index.html")
//                let dir = (try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)).absoluteString
//                print(dir)
//                guard let file = fileURL.path.withCString({ pathPointer in "rb".withCString({ fopen(pathPointer, $0) }) }) else {
//                           fatalError()
//                       }
        //        server["/test/"] = directoryBrowser(fileURL.path)
    }
    
}
