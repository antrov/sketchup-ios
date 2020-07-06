//
//  ApiEvent.swift
//  sketchvr
//
//  Created by Hubert Andrzejewski on 12/03/2020.
//  Copyright © 2020 Hubert Andrzejewski. All rights reserved.
//

import Foundation
import ObjectMapper

class ApiEvent: Mappable {
    
    enum EventType: String {
        case screenshot = "event.screenshot"
    }
    
    var type: EventType!
    var data: Data?
    
    required init?(map: Map) {
        if map.JSON["type"] == nil {
            return nil
        }
    }
    
    func mapping(map: Map) {
        type <- map["type"]
        data <- (map["data"], TransformOf<Data, String>(fromJSON: { Data(base64Encoded: $0!) }, toJSON: { $0?.base64EncodedString() }))
    }
    
    
}
