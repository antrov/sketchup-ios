//
//  ApiAction.swift
//  sketchvr
//
//  Created by Hubert Andrzejewski on 12/03/2020.
//  Copyright © 2020 Hubert Andrzejewski. All rights reserved.
//

import Foundation
import ObjectMapper

class ApiAction: Mappable {
    
    enum ActionType: String {
        case quaternion = "action.quaternion"
        case screenshot = "action.screenshot"
        case stepForward = "action.step.forward"
        case stepBackward = "action.step.backward"
    }
    
    
    var type: ActionType!
    var quaternion: [Float]?
    
    required init?(map: Map) {
        if map.JSON["type"] == nil {
            return nil
        }
    }
    
    init(_ actionType: ActionType) {
        self.type = actionType
    }
    
    init(step action: ActionType, quaternion: [Float]) {
        self.type = action
        self.quaternion = quaternion
    }
    
    func mapping(map: Map) {
        type <- map["type"]
        quaternion <- map["quaternion"]
    }
    
}
