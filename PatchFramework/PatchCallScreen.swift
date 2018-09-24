//
//  PatchCallScreen.swift
//  PatchSdk
//
//  Created by Sanyam Jain on 05/09/18.
//  Copyright © 2018 Sanyam Jain. All rights reserved.
//

import UIKit
import PatchFrameworkPrivate

class PatchCallScreen: UIViewController {
    var pjsipInstance: PJSUAWrapper = PJSUAWrapper()
    var timer = Timer()
    var seconds = 0;
    var isTimerRunning = false
    var context: String = ""
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var callContext: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        callContext.text = context
        self.startTimer()
        let status = pjsipInstance.start()
        if (status == "SUCCESS") {
            print("Pjsua started")
        } else {
            print("pjsua registeration failed")
        }
        // Do any additional setup after loading the view.
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
        seconds += 1     //This will decrement(count down)the seconds.
        timerLabel.text = timeString(time: TimeInterval(seconds))
    }
    
    @IBAction func endCall() {
        print("end call is pressed")
        self.navigationController?.popToRootViewController(animated: true)
        self.pjsipInstance.stop()

        
    }
    
    

}
