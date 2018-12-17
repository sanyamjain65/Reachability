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
    var voipToken: String = ""
    var callId: String = ""
    var sid: String = ""
    var initiatorId: String = ""
    var host: String = ""
    var isSigsockRunning: Bool = false
    let imageCache = NSCache<NSString, UIImage>()
    var isPstn: Bool = false
    var calleePhone: String = ""
    var calleeCC: String = ""
    
    func setCalleeCc(cc: String) {
        self.calleeCC = cc
    }
    
    func getCalleeCc() -> String {
        return calleeCC
    }
    
    func setCalleePhone(phone: String) {
        self.calleePhone = phone
    }
    
    func getCalleePhone() -> String {
        return self.calleePhone
    }
    
    func setIsPSTN(isPstn: Bool) {
        self.isPstn = isPstn
    }
    
    func getIsPstn() -> Bool {
        return self.isPstn
    }
    
    func setIsSigsockRunning(isSigsockRunning: Bool) {
        self.isSigsockRunning = isSigsockRunning
    }
    
    func getIsSigsockRunning() -> Bool {
        return self.isSigsockRunning
    }
    
    func setHost(host: String) {
        self.host = host
    }
    
    func getHost() -> String {
        return self.host
    }
    
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
    func setJwtToken(token: String) {
        self.voipToken = token
    }
    func getJwtToken() -> String {
        return self.voipToken
    }
    
    func setCallId(callId: String) {
        self.callId = callId
    }
    
    func getCallId() -> String {
        return self.callId
    }
    
    func setSid(sid: String) {
        self.sid = sid
    }
    
    func getSid() -> String {
        return self.sid
    }
    
    func setInitiatorId(initiatorId: String) {
        self.initiatorId = initiatorId
    }
    
    func getInitiatorId() -> String {
        return self.initiatorId
    }
    
}
