//
//  PatchCallScreen.swift
//  PatchSdk
//
//  Created by Sanyam Jain on 05/09/18.
//  Copyright © 2018 Sanyam Jain. All rights reserved.
//

import UIKit
import PatchFrameworkPrivate
import SocketIO

class PatchCallScreen: UIView {
    var callManager: CallManager!
    var pjsipInstance: PJSUAWrapper = PJSUAWrapper()
    var timer = Timer()
    var seconds = 0;
    var isTimerRunning = false
    let nibName = "PatchCallScreen"
    var contentView: UIView!
    var  manager: SocketManager? = nil
    var socket: SocketIOClient? = nil
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var callLabel: UILabel!
    override init(frame: CGRect) {
        // For use in code
        super.init(frame: frame)
        setUpView()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        // For use in Interface Builder
        super.init(coder: aDecoder)
        setUpView()
    }

    private func setUpView() {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: self.nibName, bundle: bundle)
        self.contentView = nib.instantiate(withOwner: self, options: nil).first as! UIView

        contentView.center = self.center
        contentView.autoresizingMask = []
        contentView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(contentView)
        
//        startPjsip()
    }
    
    func startPjsip() {
//        print("call context is \(context)")
//        callLabel.text = context
        
        
        
    }
    
    func initCallSock() {
        callManager = PatchDelegate.callManager
        self.startTimer()
        manager = SocketManager(socketURL:  URL(string: "http://139.59.22.182:8088:7503")!, config:[.log(true), .forceNew(true),.reconnectAttempts(5),.reconnectWait(6000),.connectParams(["jwt":""]),.forceWebsockets(true),.compress])
        socket = manager?.defaultSocket
        
        socket?.on(clientEvent: .connect) {data, ack in
            print("socket connected")
        }
        socket?.on(clientEvent: .disconnect) {data, ack in
            print("socket disconnected")
            print(data)
        }
        socket?.on(clientEvent: .error) {data, ack in
            print("socket error")
            print(data)
        }
        socket?.on(clientEvent: .statusChange) {data, ack in
            print("socket status change")
            print(data)
        }
        socket?.on("connection") { data, ack in
            let status = self.pjsipInstance.start()
            if (status == "SUCCESS") {
                Singleton.shared.setPjsipStatus(status: true)
                self.socket?.emit("call_voip","")
                print("Pjsua started")
            } else {
                Singleton.shared.setPjsipStatus(status: false)
                print("pjsua registeration failed")
            }
        }
        
        socket?.connect()
        
    }
    
    @IBAction func close() {
        let call = Call(uuid: Singleton.shared.getUUID(), handle: Singleton.shared.getHandle())
        callManager.end(call: call)
        pjsipInstance.stop()
        self.removeFromSuperview()
        timer.invalidate()
    }
    
    func closeCallkit() {
        pjsipInstance.stop()
        self.removeFromSuperview()
        timer.invalidate()
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(PatchCallScreen.updateTimer)), userInfo: nil, repeats: true)
        print(timer)
    }
    
    func timeString(time:TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"%02i:%02i:%02i", hours, minutes, seconds)
    }
    
    @objc func updateTimer() {
        seconds += 1     //This will increementthe seconds.
        timerLabel.text = timeString(time: TimeInterval(seconds))
    }
}
