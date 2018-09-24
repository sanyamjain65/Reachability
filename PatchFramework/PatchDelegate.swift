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



@UIApplicationMain
public class PatchDelegate: UIResponder, UIApplicationDelegate, PKPushRegistryDelegate, CXProviderDelegate, UINavigationControllerDelegate {
    public var window: UIWindow?
    static var pjsipInstance: PJSUAWrapper = PJSUAWrapper()
    static var sigsockInstance: Sigsock? = Sigsock()
    static var context: String = ""
    
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
//        if let appDelegate = UIApplication.shared.delegate as? PatchDelegate {
//            appDelegate.registreVoIP()
//        }
        // Override point for customization after application launch.
        return true
    }
    
    public func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    public func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    public func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    public func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    public func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    public func registreVoIP() {
        print("Called register voip")
        let voipRegistry =   PKPushRegistry(queue: DispatchQueue.main)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [.voIP]
//        DispatchQueue.global(qos: .userInitiated).async {
            PatchDelegate.sigsockInstance?.startSigsock()
//        }
    }
    
    public func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        if pushCredentials.token.count == 0 {
            print("invalid token")
            return
        }
        let token = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
        print("voip token: \(token)")
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
        let config = CXProviderConfiguration(localizedName: "HealthifyMe")
        if #available(iOS 11.0, *) {
            config.includesCallsInRecents = true
        } else {
            // Fallback on earlier versions
        }
        let provider = CXProvider(configuration: config)
        provider.setDelegate(self, queue: nil)
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: callContext)
        PatchDelegate.context = callContext
        provider.reportNewIncomingCall(with: UUID(), update: update, completion: { error in })
    }
    
    public func providerDidReset(_ provider: CXProvider) {
        
    }
    
    public func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {

        let bundle = Bundle(for: PatchDelegate.self)
        self.window = UIWindow(frame: UIScreen.main.bounds)
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "PatchStoryboard", bundle: bundle)
        let exampleViewController: PatchCallScreen = mainStoryboard.instantiateViewController(withIdentifier: "PatchCallScreen") as! PatchCallScreen
        exampleViewController.context = PatchDelegate.context
        if let navigationController = self.window?.rootViewController as? UINavigationController
        {
            navigationController.pushViewController(exampleViewController, animated: true)
        }
        else
        {
            print("Navigation Controller not Found")
        }
//        self.window?.rootViewController = exampleViewController
////        let navigationController = self.window?.rootViewController as! UINavigationController
////        navigationController.pushViewController(exampleViewController, animated: true)
//        self.window?.makeKeyAndVisible()
        action.fulfill()
        
    }
    
    public func makeCall(withContext callContext: String) {
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
            
        })
    }
    
    public func callAccepted(withContext callContext: String, withProvider provider: CXProvider ,withController controller: CXCallController) {
        DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now()) {
            provider.reportOutgoingCall(with: controller.callObserver.calls[0].uuid, connectedAt: nil)
        }
    }
    
    public func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        
        action.fulfill()
    }
}
