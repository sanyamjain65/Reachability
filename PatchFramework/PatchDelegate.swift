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

let staging: Bool = true

class PatchDelegate: UIViewController, PKPushRegistryDelegate, CXProviderDelegate {
    // initializing variabless
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
    static var callType: String = ""
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    static var providerConfiguration: CXProviderConfiguration {
        let providerConfiguration = CXProviderConfiguration(localizedName: "Patch")
        providerConfiguration.supportsVideo = false
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.supportedHandleTypes = [.generic]
        return providerConfiguration
    }
    
    // Handling of voip notification. protocol functions of PKPushRegistry
    func registreVoIP(withRootView rootview: UIViewController) {
        if staging {
            print("Called register voip")
            print("view controllers are \(rootview)")
        }
        initProvider()
        PatchDelegate.navCtrl = rootview
        let voipRegistry =   PKPushRegistry(queue: DispatchQueue.main)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [.voIP]
        NotificationCenter.default.addObserver(self, selector: #selector(self.messagereceived(notification:)), name: NSNotification.Name(rawValue: "MessageReceived"), object: nil)
    }
    
    @objc func messagereceived(notification:Notification)
    {
        let message = notification.object as? String
        if message == "cancel" {
            guard let call = PatchDelegate.callManager.callWithUUID(uuid: Singleton.shared.getUUID()) else {
                return
            }
            stopAudio()
            PatchDelegate.callManager.end(call: call)
            call.end()
            PatchDelegate.incomingTimer.invalidate()
        }
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        if pushCredentials.token.count == 0 {
            if staging {
                print("invalid token")
            }
            return
        }
        PatchDelegate.voipToken = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
        if staging {
            print("voip token: \(PatchDelegate.voipToken)")
        }
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        let payloadDict = payload.dictionaryPayload["aps"] as? Dictionary<String, String>
        guard let message = payloadDict?["alert"] else {
            if staging {
                print("recieved payload with no message")
            }
            return
        }
        guard let context = payloadDict?["context"] else {
            print("Server error while receiving a call")
            return
        }
        guard let host = payloadDict?["host"] else {
            print("Server error while receiving a call")
            return
        }
        let initiator: [String: Any] = (payloadDict?["from"] as? Dictionary<String, String>)!
        initiatorId = initiator["id"] as! String
        callId = (payloadDict?["call"])!
        sid = (payloadDict?["sid"])!
        let sigsockStatus: Bool = Singleton.shared.getIsSigsockRunning()
        if sigsockStatus {
            if staging {
                print("sigsock is running")
            }
        } else {
            PatchDelegate.sigsockInstance?.startSigsock()
        }
        Singleton.shared.setHost(host: host)
        let backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now()) {
            Singleton.shared.setHandle(handle: context)
            Singleton.shared.setCallId(callId: self.callId)
            Singleton.shared.setSid(sid: self.sid)
            Singleton.shared.setInitiatorId(initiatorId: self.initiatorId)
            PatchDelegate.displayIncomingCall(uuid: UUID(), handle: context, hasVideo: false) { _ in
                UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            }
        }
    }
    
    func initProvider() {
        PatchDelegate.provider = CXProvider(configuration: type(of: self).providerConfiguration)
        PatchDelegate.provider?.setDelegate(self, queue: nil)
    }
    
    static func lockOrientation() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    static func reportIncomingCall(uuid: UUID, handle: String, hasVideo: Bool = false, completion: ((NSError?) -> Void)?) {
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: handle)
        update.hasVideo = hasVideo
        PatchDelegate.context = Singleton.shared.getHandle()
        PatchDelegate.callType = "incoming"
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
    
    
    func providerDidReset(_ provider: CXProvider) {
        stopAudio()
        for call in PatchDelegate.callManager.calls {
            call.end()
        }
        PatchDelegate.callManager.removeAllCalls()
    }
    
    
    
    func openIncomingCallkitScreen(withContext callContext : String) {
    }
    
    
    func setFrame(appSelf: UIViewController) {
        PatchDelegate.VC = appSelf
    }
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        startAudio()
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        stopAudio()
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
        if staging {
            print("call context in patchdelegate \(PatchDelegate.context)")
            print("bounds are \(self.view.bounds)")
        }
        PatchDelegate.navCtrl?.present(self, animated: false, completion: nil)
        //
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
        if staging {
            print("rootviewController is \(String(describing: PatchDelegate.navCtrl))")
            print("visible view Controller is \(String(describing: PatchDelegate.navCtrl?.presentedViewController))")
        }
        //
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
        PatchDelegate.navCtrl?.present(self, animated: false, completion: nil)
        Singleton.shared.setUUID(uuid: action.callUUID)
        Singleton.shared.setHandle(handle: action.handle.value)
        let call = Call(uuid: action.callUUID, outgoing: true, handle: action.handle.value)
        call.connectedStateChanged = { [weak self, weak call] in
            guard let call = call else { return }
            if call.connectedState == .pending {
                if staging {
                    print("call is connecting")
                }
                PatchDelegate.provider?.reportOutgoingCall(with: call.uuid, startedConnectingAt: nil)
            } else if call.connectedState == .complete {
                if staging {
                    print("call connection is completed")
                }
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
                    PatchDelegate.callType = "outgoing"
                    PatchDelegate.navCtrl?.view.addSubview(modalView)
                    modalView.initCallSock(callContext: Singleton.shared.getHandle(), call: "outgoing")
                } else {
                    PatchDelegate.callType = "outgoing"
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
            if staging {
                print("call missed....closing call")
            }
            let preferences  = UserDefaults.standard
            let accountId = preferences.object(forKey: "accountId")
            PatchDelegate.sigsockInstance?.miss(initiatorId: Singleton.shared.getInitiatorId(), accountId: accountId as! String , callId: Singleton.shared.getCallId(), sid: Singleton.shared.getSid())
            guard let call = PatchDelegate.callManager.callWithUUID(uuid: Singleton.shared.getUUID()) else {
                return
            }
            stopAudio()
            callManager.end(call: call)
            PatchDelegate.incomingTimer.invalidate()
            PatchDelegate.incomingCallSeconds = 60
        }
    }
    
    func callAccepted(withContext callContext: String, withProvider provider: CXProvider ,withController controller: CXCallController) {
        DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now()) {
            provider.reportOutgoingCall(with: controller.callObserver.calls[0].uuid, connectedAt: nil)
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        if staging {
            print("callType is \(PatchDelegate.callType)")
        }
        if PatchDelegate.callType != "outgoing" {
            dismiss(animated: false, completion: nil)
            let pjsipstatus: Bool  = Singleton.shared.getPjsipStatus()
            PatchDelegate.incomingTimer.invalidate()
            if pjsipstatus == true {
                NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "MessageReceived"),object: "endCall"))
//                let modelView = PatchCallScreen.init(frame: self.view.bounds)
//                modelView.closeCallkit()
//                PatchDelegate.modalView?.removeFromSuperview()
            } else {
                let preferences  = UserDefaults.standard
                let accountId = preferences.object(forKey: "accountId")
                PatchDelegate.sigsockInstance?.decline(initiatorId: Singleton.shared.getInitiatorId(), accountId: accountId as! String , callId: Singleton.shared.getCallId(), sid: Singleton.shared.getSid())
                
            }
            Singleton.shared.setCallId(callId: "")
            guard let call = PatchDelegate.callManager.callWithUUID(uuid: action.callUUID) else {
                action.fail()
                return
            }
            stopAudio()
            call.end()
            action.fulfill()
            
        } else {
            dismiss(animated: false, completion: nil)
            PatchDelegate.callType = ""
            guard let call = PatchDelegate.callManager.callWithUUID(uuid: action.callUUID) else {
                action.fail()
                return
            }
            Singleton.shared.setCallId(callId: "")
            stopAudio()
            call.end()
            action.fulfill()
        }
        
    }
}
