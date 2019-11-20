//
//  RemoteFilesManager.swift
//  sketchvr
//
//  Created by Hubert Andrzejewski on 19/11/2019.
//  Copyright © 2019 Hubert Andrzejewski. All rights reserved.
//

import Foundation
import ZIPFoundation
import Promises

final class RemoteFilesManager {
    
    private let appDownloadURL = URL(string: "https://github.com/antrov/sketchvr-web/releases/latest/download/sketchvr-web.zip")!
    
    let appLocalURL: URL
    
    init() throws {
        appLocalURL = try FileManager.default.url(for: .documentDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: false).appendingPathComponent("app")
    }
    
    func downloadWebApp(forced: Bool = false) -> Promise<URL> {
        let fileManager = FileManager.default
        let fileExists = fileManager.fileExists(atPath: self.appLocalURL.path)
        let appLocalURL = self.appLocalURL
        
        guard !fileExists || forced else { return Promise(self.appLocalURL) }
        
        return Promise<URL> { fulfill, reject in
            URLSession.shared.downloadTask(with: self.appDownloadURL) { fileURL, _, error in
                guard error == nil else { reject(error!); return }
                guard let fileURL = fileURL else { reject(PromiseError.timedOut); return }
                
                do {
                    if fileExists {
                        try fileManager.removeItem(at: appLocalURL)
                    }
                    
                    try fileManager.createDirectory(at: appLocalURL, withIntermediateDirectories: true, attributes: nil)
                    try fileManager.unzipItem(at: fileURL, to: appLocalURL)
                    
                    fulfill(appLocalURL)
                } catch {
                    reject(error)
                }
            }
            .resume()
        }
    }
    
    // MARK: - Private methods
    
}
