//
//  PatchDelegate.swift
//  TestingDelegate
//
//  Created by Sanyam Jain on 18/09/18.
//  Copyright © 2018 Sanyam Jain. All rights reserved.
//

import Foundation
import UIKit
import PushKit
import CallKit
import PatchFrameworkPrivate
//import Obfuscator

class PatchDelegate: UIViewController, PKPushRegistryDelegate, CXProviderDelegate {

    
    
    static let callManager = CallManager()
    static var provider: CXProvider? = nil
    public var window: UIWindow?
    static var sigsockInstance: Sigsock? = Sigsock()
    static var context: String = ""
    static var navCtrl: UIViewController?
    static var VC: UIViewController?
    static var modalView: UIView? = nil
    static var voipToken: String = ""
    var callId: String = ""
    var sid: String = ""
    var initiatorId: String = ""
    static var incomingCallSeconds = 60
    static var incomingTimer = Timer()
    static var enableAllOrientation = false
    static var orientationLock = UIInterfaceOrientationMask.portrait
    
    
    static var providerConfiguration: CXProviderConfiguration {
        let providerConfiguration = CXProviderConfiguration(localizedName: "Patch")
        providerConfiguration.supportsVideo = false
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.supportedHandleTypes = [.generic]
        return providerConfiguration
    }
    
    func registreVoIP(withRootView rootview: UIViewController) {
        
//        print("Called register voip")
//        print("view controllers are \(rootview)")
        initProvider()
        PatchDelegate.navCtrl = rootview
        let voipRegistry =   PKPushRegistry(queue: DispatchQueue.main)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [.voIP]
        
//        PatchDelegate.sigsockInstance?.startSigsock()
    }
    
    static func lockOrientation() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    func initProvider() {
       PatchDelegate.provider = CXProvider(configuration: type(of: self).providerConfiguration)
        PatchDelegate.provider?.setDelegate(self, queue: nil)
    }
    
   static func reportIncomingCall(uuid: UUID, handle: String, hasVideo: Bool = false, completion: ((NSError?) -> Void)?) {
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: handle)
        update.hasVideo = hasVideo
        PatchDelegate.context = Singleton.shared.getHandle()
    PatchDelegate.provider?.reportNewIncomingCall(with: uuid, update: update, completion: { (error) in
        if error == nil {
            Singleton.shared.setUUID(uuid: uuid)
            Singleton.shared.setHandle(handle: handle)
            let call = Call(uuid: uuid, handle: handle)
            PatchDelegate.callManager.add(call: call)
            PatchDelegate.incomingTimer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(PatchDelegate.incomingCallTimer)), userInfo: nil, repeats: true)
        }
        completion?(error as NSError?)
    })
    }
    
    static func displayIncomingCall(uuid: UUID, handle: String, hasVideo: Bool = false, completion: ((NSError?) -> Void)?) {
        PatchDelegate.reportIncomingCall(uuid: uuid, handle: handle, hasVideo: hasVideo, completion: completion)
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        if pushCredentials.token.count == 0 {
//            print("invalid token")
            return
        }
        PatchDelegate.voipToken = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
//        print("voip token: \(PatchDelegate.voipToken)")
    }
    
    func providerDidReset(_ provider: CXProvider) {
        stopAudio()
        
        for call in PatchDelegate.callManager.calls {
            call.end()
        }
        
        PatchDelegate.callManager.removeAllCalls()
    }
    
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        let payloadDict = payload.dictionaryPayload["aps"] as? Dictionary<String, String>
        guard let message = payloadDict?["alert"] else {
//            print("recieved payload with no message")
            return
        }
        
        let initiator: [String: Any] = (payloadDict?["from"] as? Dictionary<String, String>)!
        initiatorId = initiator["id"] as! String
        callId = (payloadDict?["call"])!
        sid = (payloadDict?["sid"])!
        
        Singleton.shared.setCallId(callId: callId)
        Singleton.shared.setSid(sid: sid)
        Singleton.shared.setInitiatorId(initiatorId: initiatorId)
        
        openIncomingCallkitScreen(withContext: message)
    }
    
    func openIncomingCallkitScreen(withContext callContext : String) {
    }
    
    
    func setFrame(appSelf: UIViewController) {
        PatchDelegate.VC = appSelf
    }
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        startAudio()
    }
    
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        guard let call = PatchDelegate.callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        
        // 2.
        configureAudioSession()
        // 3.
        call.answer()
        
//        print("call context in patchdelegate \(PatchDelegate.context)")
//        print("bounds are \(self.view.bounds)")
        let modalView = PatchCallScreen(frame: self.view.bounds)
        PatchDelegate.modalView = modalView
        let preferences  = UserDefaults.standard
        let accountId = preferences.object(forKey: "accountId")
        PatchDelegate.incomingTimer.invalidate()
        PatchDelegate.sigsockInstance?.answer(initiatorId: Singleton.shared.getInitiatorId(), accountId: accountId as! String , callId: Singleton.shared.getCallId(), sid: Singleton.shared.getSid())
        if PatchDelegate.navCtrl?.presentedViewController == nil {
            PatchDelegate.navCtrl?.view.addSubview(modalView)
            modalView.initCallSock(callContext: PatchDelegate.context, call: "incoming")
        } else {
            PatchDelegate.navCtrl?.presentedViewController?.view.addSubview(modalView)
            modalView.initCallSock(callContext: PatchDelegate.context, call: "incoming")
        }
//        print("rootviewController is \(String(describing: PatchDelegate.navCtrl))")
//        print("visible view Controller is \(String(describing: PatchDelegate.navCtrl?.presentedViewController))")
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        guard let call = PatchDelegate.callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        
        // 1.
        call.state = action.isOnHold ? .held : .active
        
        // 2.
        if call.state == .held {
            stopAudio()
        } else {
            startAudio()
        }
        
        // 3.
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        Singleton.shared.setUUID(uuid: action.callUUID)
        Singleton.shared.setHandle(handle: action.handle.value)
        let call = Call(uuid: action.callUUID, outgoing: true, handle: action.handle.value)
        configureAudioSession()
        call.connectedStateChanged = { [weak self, weak call] in
            guard let call = call else { return }
            
            if call.connectedState == .pending {
//                print("call is connecting")
                PatchDelegate.provider?.reportOutgoingCall(with: call.uuid, startedConnectingAt: nil)
            } else if call.connectedState == .complete {
//                print("call connection is completed")
                PatchDelegate.provider?.reportOutgoingCall(with: call.uuid, connectedAt: nil)
            }
        }
        call.start { [weak self, weak call] success in
            guard let call = call else { return }
            
            if success {
                action.fulfill()
                let modalView = PatchCallScreen(frame: (self?.view.bounds)!)
                PatchDelegate.modalView = modalView
                if PatchDelegate.navCtrl?.presentedViewController == nil {
                    PatchDelegate.navCtrl?.view.addSubview(modalView)
                    modalView.initCallSock(callContext: Singleton.shared.getHandle(), call: "outgoing")
                } else {
                    PatchDelegate.navCtrl?.presentedViewController?.view.addSubview(modalView)
                    modalView.initCallSock(callContext: Singleton.shared.getHandle(), call: "outgoing")
                }
                PatchDelegate.callManager.add(call: call)
            } else {
                action.fail()
            }
        }
    }
    
    @objc static func incomingCallTimer() {
        PatchDelegate.incomingCallSeconds -= 1
        if PatchDelegate.incomingCallSeconds == 0 {
//            print("call missed....closing call")
            let preferences  = UserDefaults.standard
            let accountId = preferences.object(forKey: "accountId")
            PatchDelegate.sigsockInstance?.miss(initiatorId: Singleton.shared.getInitiatorId(), accountId: accountId as! String , callId: Singleton.shared.getCallId(), sid: Singleton.shared.getSid())
            guard let call = PatchDelegate.callManager.callWithUUID(uuid: Singleton.shared.getUUID()) else {
                return
            }
            stopAudio()
            callManager.end(call: call)
            PatchDelegate.incomingTimer.invalidate()
        }
    }
    
    func callAccepted(withContext callContext: String, withProvider provider: CXProvider ,withController controller: CXCallController) {
        DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now()) {
            provider.reportOutgoingCall(with: controller.callObserver.calls[0].uuid, connectedAt: nil)
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        let pjsipstatus: Bool  = Singleton.shared.getPjsipStatus()
        PatchDelegate.incomingTimer.invalidate()
        if pjsipstatus == true {
            let modelView = PatchCallScreen.init(frame: self.view.bounds)
            modelView.closeCallkit()
            PatchDelegate.modalView?.removeFromSuperview()
        } else {
            let preferences  = UserDefaults.standard
            let accountId = preferences.object(forKey: "accountId")
            PatchDelegate.sigsockInstance?.decline(initiatorId: Singleton.shared.getInitiatorId(), accountId: accountId as! String , callId: Singleton.shared.getCallId(), sid: Singleton.shared.getSid())
        }
        guard let call = PatchDelegate.callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        stopAudio()
        call.end()
        action.fulfill()
    }
}
