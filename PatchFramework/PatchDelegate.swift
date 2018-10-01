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

public class PatchDelegate: UIViewController, PKPushRegistryDelegate, CXProviderDelegate {
    static let callManager = CallManager()
    static var provider: CXProvider? = nil
    public var window: UIWindow?
    static var sigsockInstance: Sigsock? = Sigsock()
    static var context: String = ""
    static var navCtrl: UIViewController?
    static var VC: UIViewController?
    static var modalView: UIView? = nil
    static var voipToken: String = ""
    
    
    static var providerConfiguration: CXProviderConfiguration {
        let providerConfiguration = CXProviderConfiguration(localizedName: "HealthifyMe")
        
        providerConfiguration.supportsVideo = false
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.supportedHandleTypes = [.generic]
        return providerConfiguration
    }
    
    public func registreVoIP(withRootView rootview: UIViewController) {
        
        print("Called register voip")
        print("view controllers are \(rootview)")
        initProvider()
        PatchDelegate.navCtrl = rootview
        let voipRegistry =   PKPushRegistry(queue: DispatchQueue.main)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [.voIP]
//        DispatchQueue.global(qos: .userInitiated).async {
            PatchDelegate.sigsockInstance?.startSigsock()
//        }
    }
    
    func initProvider() {
       PatchDelegate.provider = CXProvider(configuration: type(of: self).providerConfiguration)
        PatchDelegate.provider?.setDelegate(self, queue: nil)
    }
    
   static func reportIncomingCall(uuid: UUID, handle: String, hasVideo: Bool = false, completion: ((NSError?) -> Void)?) {
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: handle)
        update.hasVideo = hasVideo
    PatchDelegate.provider?.reportNewIncomingCall(with: uuid, update: update, completion: { (error) in
        if error == nil {
            Singleton.shared.setUUID(uuid: uuid)
            Singleton.shared.setHandle(handle: handle)
            let call = Call(uuid: uuid, handle: handle)
            PatchDelegate.callManager.add(call: call)
        }
        completion?(error as NSError?)
    })
    }
    
    static func displayIncomingCall(uuid: UUID, handle: String, hasVideo: Bool = false, completion: ((NSError?) -> Void)?) {
        PatchDelegate.reportIncomingCall(uuid: uuid, handle: handle, hasVideo: hasVideo, completion: completion)
    }
    
    public func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        if pushCredentials.token.count == 0 {
            print("invalid token")
            return
        }
        PatchDelegate.voipToken = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
        print("voip token: \(PatchDelegate.voipToken)")
    }
    
    public func providerDidReset(_ provider: CXProvider) {
        stopAudio()
        
        for call in PatchDelegate.callManager.calls {
            call.end()
        }
        
        PatchDelegate.callManager.removeAllCalls()
    }
    
    public func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        let payloadDict = payload.dictionaryPayload["aps"] as? Dictionary<String, String>
        guard let message = payloadDict?["alert"] else {
            print("recieved payload with no message")
            return
        }
        openIncomingCallkitScreen(withContext: message)
    }
    
    public func openIncomingCallkitScreen(withContext callContext : String) {
//        let config = CXProviderConfiguration(localizedName: "HealthifyMe")
//        if #available(iOS 11.0, *) {
//            config.includesCallsInRecents = true
//        } else {
//            // Fallback on earlier versions
//        }
//        let provider = CXProvider(configuration: config)
//        provider.setDelegate(self, queue: nil)
//        let update = CXCallUpdate()
//        update.remoteHandle = CXHandle(type: .generic, value: callContext)
//        PatchDelegate.context = callContext
//        provider.reportNewIncomingCall(with: UUID(), update: update, completion: { error in })
    }
    
    
    public func setFrame(appSelf: UIViewController) {
        PatchDelegate.VC = appSelf
    }
    
    public func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        startAudio()
    }
    
    
    public func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        guard let call = PatchDelegate.callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        
        // 2.
        configureAudioSession()
        // 3.
        call.answer()
        
        print("call context in patchdelegate \(PatchDelegate.context)")
        let modalView = PatchCallScreen(frame: self.view.bounds)
        PatchDelegate.modalView = modalView
        if PatchDelegate.navCtrl?.presentedViewController == nil {
            PatchDelegate.navCtrl?.view.addSubview(modalView)
            modalView.startPjsip()
        } else {
            PatchDelegate.navCtrl?.presentedViewController?.view.addSubview(modalView)
            modalView.startPjsip()
        }
        print("rootviewController is \(String(describing: PatchDelegate.navCtrl))")
        print("visible view Controller is \(String(describing: PatchDelegate.navCtrl?.presentedViewController))")
      
        
//        PatchDelegate.navCtrl?.view.addSubview(modalView)
//        PatchDelegate.navCtrl?.presentedViewController?.view.addSubview(PatchDelegate.modalView!)
//        self.window?.rootViewController.viewContr
//        let presentVC = PatchDelegate.navCtrl?.visibleViewController
//        print("top view controllers in stack are\(String(describing: PatchDelegate.navCtrl?.topViewController))")
//        let bundle = Bundle(identifier: "com.patch.PatchFramework")
//        let storyboard = UIStoryboard.init(name: "PatchStoryboard", bundle: bundle)
//
//        let viewController = storyboard.instantiateViewController(withIdentifier: "PatchCallScreen")
//
//        let top = UIApplication.shared.keyWindow?.rootViewController
//
//        top?.present(viewController, animated: true, completion: nil)
//        let bundle = Bundle(identifier: "com.patch.PatchFramework")
//        let controller = UIViewController(nibName: "PatchCallScreen", bundle: bundle)
//        PatchDelegate.VC?.present(controller, animated: true, completion: nil)
//        let bundle = Bundle(identifier: "com.patch.PatchFramework")
//        self.window = UIWindow(frame: UIScreen.main.bounds)
//        let mainStoryboard: UIStoryboard = UIStoryboard.init(name: "PatchStoryboard", bundle: bundle)
//        let exampleViewController = mainStoryboard.instantiateViewController(withIdentifier: "PatchCallScreen")
//        PatchDelegate.navCtrl?.present(exampleViewController, animated: true, completion: nil)
//        let nvc = UINavigationController(rootViewController: (PatchDelegate.navCtrl?.topViewController)!)
//        nvc.pushViewController(exampleViewController, animated: true)
//        print("nvc is \(nvc)")
        
//        let bundle = Bundle(identifier: "com.patch.PatchFramework")
//        self.window = UIWindow(frame: UIScreen.main.bounds)
//        let mainStoryboard: UIStoryboard = UIStoryboard.init(name: "PatchStoryboard", bundle: bundle)
//        let exampleViewController = mainStoryboard.instantiateViewController(withIdentifier: "PatchCallScreen")
////        exampleViewController.context = PatchDelegate.context
////        exampleViewController.currentVC = PatchDelegate.navCtrl
////        present(exampleViewController, animated: true, completion: nil)
////        navigationController?.pushViewController(exampleViewController, animated: true)
//
////        PatchDelegate.navCtrl?.pushViewController(exampleViewController, animated: true)
//        self.window?.rootViewController = exampleViewController
//        self.window?.makeKeyAndVisible()
        action.fulfill()
    }
    
    public func makeCall(currentVc: UIViewController ,withContext callContext: String) {
        let config = CXProviderConfiguration(localizedName: "HealthifyMe")
        if #available(iOS 11.0, *) {
            config.includesCallsInRecents = true
        } else {
            // Fallback on earlier versions
        }
        let provider = CXProvider(configuration: config)
        provider.setDelegate(self, queue: nil)
        let controller = CXCallController()
        let transaction = CXTransaction(action: CXStartCallAction(call: UUID(), handle: CXHandle(type: .generic, value: callContext)))
        controller.request(transaction, completion: { error in
            
//            print("visible view Controller is \(String(describing: PatchDelegate.navCtrl?.presentedViewController))")
        })
    }
    
    public func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
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
    
    public func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        Singleton.shared.setUUID(uuid: action.callUUID)
        Singleton.shared.setHandle(handle: action.handle.value)
        let call = Call(uuid: action.callUUID, outgoing: true, handle: action.handle.value)
        configureAudioSession()
        call.connectedStateChanged = { [weak self, weak call] in
            guard let call = call else { return }
            
            if call.connectedState == .pending {
                print("call is connecting")
                PatchDelegate.provider?.reportOutgoingCall(with: call.uuid, startedConnectingAt: nil)
            } else if call.connectedState == .complete {
                print("call connection is completed")
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
                    modalView.startPjsip()
                } else {
                    PatchDelegate.navCtrl?.presentedViewController?.view.addSubview(modalView)
                    modalView.startPjsip()
                }
                PatchDelegate.callManager.add(call: call)
            } else {
                action.fail()
            }
        }
    }
    
    public func callAccepted(withContext callContext: String, withProvider provider: CXProvider ,withController controller: CXCallController) {
        DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now()) {
            provider.reportOutgoingCall(with: controller.callObserver.calls[0].uuid, connectedAt: nil)
        }
    }
    
    public func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        let pjsipstatus: Bool  = Singleton.shared.getPjsipStatus()
        if pjsipstatus == true {
            let modelView = PatchCallScreen.init(frame: self.view.bounds)
            modelView.closeCallkit()
            PatchDelegate.modalView?.removeFromSuperview()
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
