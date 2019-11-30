//
//  LocalhostService.swift
//  sketchvr
//
//  Created by Hubert Andrzejewski on 18/11/2019.
//  Copyright © 2019 Hubert Andrzejewski. All rights reserved.
//

import Foundation
import Swifter

final class LocalhostService {
    
    struct RuntimeError: Error {
        let message: String

        init(_ message: String) {
            self.message = message
        }

        public var localizedDescription: String {
            return message
        }
    }
    
    private lazy var server: HttpServer = {
        let server = HttpServer()
        return server
    }()
    
    func serveLocalhost(from directory: URL, on port: UInt16 = 8080, publicUrl: URL? = nil) throws -> URL {
        server.stop()
        print(publicUrl)
        let block = { (request: HttpRequest) -> HttpResponse in
            var path = request.path
            path.removeFirst()
            print(path)
            
            if let publicUrl = publicUrl, path.split(separator: "/").first == "public" {
                let publicPath = path.split(separator: "/").dropFirst().joined(separator: "/")
                print("public: " + publicPath)
                request.params = ["": publicPath]
                let response = shareFilesFromDirectory(publicUrl.path)(request)
                print("public response is \(response)")
                return response
            }
            
            request.params = ["": path]
            return shareFilesFromDirectory(directory.path)(request)
        }
        
        server["/"] = block
        server["/:path/*"] = block
        server["/*"] = block
        
        server.middleware.append { request in
            print("Middleware: \(request.address ?? "unknown address") -> \(request.method) -> \(request.path)")
            return nil
        }
        
        server.notFoundHandler = { request -> HttpResponse in
            print("notFoundHandler: \(request.address ?? "unknown address") -> \(request.method) -> \(request.path)")
            return .notFound
        }
        
        print(server.routes)
        
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
