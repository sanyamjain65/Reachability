//
//  ProviderDelegate.swift
//  PatchFramework
//
//  Created by Sanyam Jain on 27/09/18.
//  Copyright © 2018 Sanyam Jain. All rights reserved.
//

import AVFoundation
import CallKit

class ProviderDelegate: NSObject {
    // 1.
    fileprivate let callManager: CallManager
    fileprivate let provider: CXProvider
    let patchDelegate = PatchDelegate()
    
    init(callManager: CallManager) {
        self.callManager = callManager
        // 2.
        provider = CXProvider(configuration: type(of: self).providerConfiguration)
        
        super.init()
        // 3.
        provider.setDelegate((self as! CXProviderDelegate), queue: nil)
    }
    
    // 4.
    static var providerConfiguration: CXProviderConfiguration {
        let providerConfiguration = CXProviderConfiguration(localizedName: "HealthifyMe")
        
        providerConfiguration.supportsVideo = false
        providerConfiguration.maximumCallsPerCallGroup = 1
        
        return providerConfiguration
    }
    
    func reportIncomingCall(uuid: UUID, handle: String, hasVideo: Bool = false, completion: ((NSError?) -> Void)?) {
        // 1.
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: handle)
        update.hasVideo = hasVideo
        
        // 2.
        provider.reportNewIncomingCall(with: uuid, update: update) { error in
            if error == nil {
                // 3.
                let call = Call(uuid: uuid, handle: handle)
                self.callManager.add(call: call)
            }
            
            // 4.
            completion?(error as? NSError)
        }
    }
    
    
}

extension ProviderDelegate: CXProviderDelegate {
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        // 1.
        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        
        // 2.
        configureAudioSession()
        // 3.
        call.answer()
        // 4.
        action.fulfill()
    }
    
    // 5.
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        startAudio()
    }
    
    func providerDidReset(_ provider: CXProvider) {
        stopAudio()
        
        for call in callManager.calls {
            call.end()
        }
        
        callManager.removeAllCalls()
    }
}
