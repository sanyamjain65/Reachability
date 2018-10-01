//
//  Singleton.swift
//  PatchFramework
//
//  Created by Sanyam Jain on 27/09/18.
//  Copyright © 2018 Sanyam Jain. All rights reserved.
//

import Foundation

class Singleton {
    static let shared = Singleton()
    var pjsipStatus: Bool = false
    var uuid: UUID? = nil
    var handle: String = ""
    
    func setPjsipStatus(status: Bool){
        //Code Process
        self.pjsipStatus = status
    }
    
    func setUUID(uuid: UUID) {
        self.uuid = uuid
    }
    
    func setHandle(handle: String) {
        self.handle = handle
    }

    func getUUID() -> UUID {
        return self.uuid!
    }
    
    func getHandle() -> String {
        return self.handle
    }
    func getPjsipStatus() -> Bool {
        return self.pjsipStatus
    }
    
}
