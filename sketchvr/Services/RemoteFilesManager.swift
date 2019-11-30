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
    private var selectedFiles: [String]?
    
    let appLocalURL: URL
    let cloudUrl: URL?
    
    init() throws {
        let fileManager = FileManager.default
        
        appLocalURL = try fileManager.url(for: .documentDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: false).appendingPathComponent("app")
        
        cloudUrl = fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
        
        guard let url = cloudUrl else { throw PromiseError.timedOut }
        if !fileManager.fileExists(atPath: url.path)  {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
        
        selectCloudFiles(by: ["Zimne Wody.obj", "Zimne Wody.mtl"])
        try syncCloud()
//
//        url.appendPathComponent("test2")
//        url.appendPathExtension("txt")
//
//        try "testttt".data(using: .utf8, allowLossyConversion: true)?.write(to: url)
////
//        let path = url.path
//
//        guard let file = path.withCString({ pathPointer in "rb".withCString({ fopen(pathPointer, $0) }) }) else {
//                    fatalError("\(errno)")
//               }
    }
    
//    https://stackoverflow.com/questions/24150061/how-to-monitor-a-folder-for-new-files-in-swift
    
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
                    
                    (try? fileManager.contentsOfDirectory(atPath: appLocalURL.path))?.forEach({ (element) in
                        print(element)
                    })
                    
                    fulfill(appLocalURL)
                } catch {
                    reject(error)
                }
            }
            .resume()
        }
    }
    
    func selectCloudFiles(by names: [String]) {
        guard let cloudUrl = cloudUrl else { return }
        
        selectedFiles = names
        names.forEach { (name) in
            try? FileManager.default.startDownloadingUbiquitousItem(at: cloudUrl.appendingPathComponent(name))
        }
    }
    
    // MARK: - Private methods
    
    var query = NSMetadataQuery()
    var obs: Any!
    
    func syncCloud() throws {
        guard let cloudUrl = cloudUrl else { return }
        
//        let fileManager = FileManager.default
//        let contents = try fileManager.contentsOfDirectory(atPath: cloudUrl.path)
        //predicateWithFormat:@"%K BEGINSWITH %@", NSMetadataItemPathKey, dirPath];
        
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        query.predicate = NSPredicate(format: "%K BEGINSWITH %@", NSMetadataItemPathKey, cloudUrl.path)
        
        let o = NotificationCenter.default.addObserver(forName: .NSMetadataQueryDidUpdate, object: nil, queue: .main) { (notification) in
            print("NSMetadataQueryDidUpdate")
            
            self.query.results.forEach { (item) in
                guard let metadata = item as? NSMetadataItem else { return }
                guard let url = metadata.value(forAttribute: NSMetadataItemURLKey) as? URL else { return }
                guard self.selectedFiles?.contains(url.lastPathComponent) == true else { return }
                guard let values = try? url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey]) else { return }
//                print(String(data: try! Data(contentsOf: url), encoding: .utf8))
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .onSelectedSkin, object: nil, userInfo: nil)
                }
//                guard let status = values.ubiquitousItemDownloadingStatus, status != .current else { return }
//                print("\(url.path) - \(status.rawValue)")
            }
        }
        
        obs = [o]
        query.start()
    }
}

extension Notification.Name {

    static let onSelectedSkin = Notification.Name("on-selected-skin")
    static let onStepForws = Notification.Name("on-selected-skissssn")
}
