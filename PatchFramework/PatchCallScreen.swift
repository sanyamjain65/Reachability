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
import AVFoundation

class PatchCallScreen: UIView {
    var callManager: CallManager!
    var pjsipInstance: PJSUAWrapper = PJSUAWrapper()
    var timer = Timer()
    var declineTimer = Timer()
    var callVoipTimer = Timer()
    var callTimer = Timer()
    var outgoingToneTimer = Timer()
    var seconds = 0;
    var sec = 2;
    var declineSeconds = 3;
    var callingSeconds = 60
    var outgoingSeconds = 2
    var speakerStatus : Bool = false
    var muteStatus: Bool = false
    var isTimerRunning = false
    let nibName = "PatchCallScreen"
    var contentView: UIView!
    var  manager: SocketManager? = nil
    var socket: SocketIOClient? = nil
    var player: AVAudioPlayer?
    var uiFrame: CGRect?
    var alone: Bool = false
    var isCallAnswered: Bool = false
    var callType: String = ""
    let ss = PatchDelegate.sigsockInstance
    
    @IBOutlet weak var bgImage: UIImageView!
    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var patchHeader: UILabel!
    @IBOutlet weak var callLabel: UILabel!
    @IBOutlet weak var callStatus: UILabel!
    @IBOutlet weak var speaker: UIButton!
    @IBOutlet weak var mute: UIButton!
    override init(frame: CGRect) {
        // For use in code
        super.init(frame: frame)
        uiFrame = frame
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
        self.contentView = nib.instantiate(withOwner: self, options: nil).first as? UIView
        contentView.center = self.center
        contentView.bounds = uiFrame!
        contentView.autoresizingMask = []
        contentView.translatesAutoresizingMaskIntoConstraints = true
        contentView.autoresizesSubviews = true
//        contentView.sizeToFit()
        addSubview(contentView)
        let preferences  = UserDefaults.standard
        let fontColor = preferences.object(forKey: "fontColor")
        let bgColor = preferences.object(forKey: "bgColor")
        let logo = preferences.object(forKey: "logo")
        if logo != nil {
            guard let url = URL(string: logo as! String) else {
                if staging {
                    print("no url specified")
                }
                return
            }
            if staging {
                print("url is \(String(describing: url))")
            }
            downloadImage(url: url) { (image) in
                if staging {
                    print("image fetched is \(String(describing: image))")
                }
                self.logoImage.image = image
            }
        } else {
            let image = UIImage(named: "patch@2x", in: Bundle(for: type(of: self)), compatibleWith: nil)
            self.logoImage.image = image
        }
        //        print("fontColor in int is \(fontColor as! Int)")
        if fontColor != nil {
            if staging {
                print("fontColor is not empty")
            }
            let labelColor: UIColor = hexStringToUIColor(hex: fontColor as! String)
            if staging {
                print("font color is\(String(describing: labelColor))")
            }
            self.patchHeader.textColor = labelColor
            self.callLabel.textColor = labelColor
            self.callStatus.textColor = labelColor
            self.timerLabel.textColor = labelColor
        } else {
            if staging {
               print("font color is empty")
            }
            self.patchHeader.textColor = UIColor.white
            self.callLabel.textColor = UIColor.white
            self.callStatus.textColor = UIColor.white
            self.timerLabel.textColor = UIColor.white
        }
        if bgColor != nil {
            if staging {
              print("bgColor is not empty")
            }
            let backgroundColor: UIColor = hexStringToUIColor(hex: bgColor as! String)
            bgImage.backgroundColor = backgroundColor
            if staging {
                print("bgColor is\(String(describing: backgroundColor))")
            }
        } else {
            if staging {
                print("bgColor is empty")
            }
            let backgroundColor: UIColor = hexStringToUIColor(hex: "#2E3558")
            bgImage.backgroundColor = backgroundColor
        }
        callStatus.text = "Dialling"
    }
    
    func downloadImage(url: URL, completion: @escaping (UIImage?) -> Void)  {
        if staging {
           print("url is \(url)")
        }
        if let cachedImage = Singleton.shared.imageCache.object(forKey: url.absoluteString as NSString) {
            if staging {
               print("logo is cached...returning it")
            }
            DispatchQueue.main.async {
                completion(cachedImage)
            }
        } else {
            if staging {
               print("logo is not cached")
            }
            PatchCallScreen.downloadData(url: url) { data, response, error in
                if let error = error {
                    completion(nil)
                } else if let data = data, let image = UIImage(data: data) {
                    Singleton.shared.imageCache.setObject(image, forKey: url.absoluteString as NSString)
                    if staging {
                        print("image cached is \(String(describing: Singleton.shared.imageCache.object(forKey: url.absoluteString as NSString)))")
                    }
                    DispatchQueue.main.async {
                        completion(image)
                    }
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    fileprivate static func downloadData(url: URL, completion: @escaping (_ data: Data?, _  response: URLResponse?, _ error: Error?) -> Void) {
        URLSession(configuration: .ephemeral).dataTask(with: URLRequest(url: url)) { data, response, error in
            completion(data, response, error)
            }.resume()
    }
    
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    func onAnswer() {
        callTimer.invalidate()
        player?.stop()
        callStatus.isHidden = true
        timerLabel.isHidden = false
        speaker.isHidden = false
        mute.isHidden = false
        self.startTimer()
        if staging {
            print("call id in patch call screen is \(Singleton.shared.getCallId())")
        }
        let preferences  = UserDefaults.standard
        let cc = preferences.object(forKey: "cc") as! String
        let phone = preferences.object(forKey: "phone") as! String
        let apikey = preferences.object(forKey: "apikey")
        let accountId = preferences.object(forKey: "accountId")
        let authData: [String: Any] = [
            "platform": "ios",
            "apikey": apikey,
            "accountId": accountId,
            "cc": cc,
            "phone": phone,
            "callId": Singleton.shared.getCallId()
        ]
        if staging {
            manager = SocketManager(socketURL:  URL(string: "https://" + Singleton.shared.getHost() + ":3001")!, config:[.log(true),.forceNew(true),.reconnectAttempts(5),.reconnectWait(6000),.connectParams(["jwt":Singleton.shared.getJwtToken()]), .forceWebsockets(true),.compress])
            socket = manager?.defaultSocket
        } else {
            manager = SocketManager(socketURL:  URL(string: "https://" + Singleton.shared.getHost() + ":3001")!, config:[.forceNew(true),.reconnectAttempts(5),.reconnectWait(6000),.connectParams(["jwt":Singleton.shared.getJwtToken()]), .forceWebsockets(true),.compress])
            socket = manager?.defaultSocket
        }
        socket?.on(clientEvent: .connect) {data, ack in
            if staging {
                print("socket connected")
            }
        }
        socket?.on(clientEvent: .disconnect) {data, ack in
            if staging {
                print("socket disconnected")
                print(data)
            }
        }
        socket?.on(clientEvent: .error) {data, ack in
            if staging {
                print("socket error")
                print(data)
            }
        }
        socket?.on(clientEvent: .statusChange) {data, ack in
            if staging {
                print("socket status change")
                print(data)
            }
        }
        socket?.on("connect") { data, ack in
            if staging {
                print ("auth data in callsock is \(authData)")
            }
            self.socket?.emit("authentication", authData)
        }
        socket?.on("authenticated") { data, ack in
            //            print(data)
            print("calling server connected")
        }
        socket?.on("disconnected") { data, ack in
            //            print(data)
            print("calling server disconnected")
            self.close()
        }
        socket?.on("call_status") { data, ack in
            if staging {
                print("call status is", data)
            }
            let dataArray = data as NSArray
            guard let dataString = dataArray[0] as? NSDictionary else {
                return
            }
            guard let isAlone = dataString["alone"] as? Bool else {
                return
            }
            self.alone = isAlone
            if (self.alone) {
                self.close()
            }
        }
        socket?.on("endpoint_ready") { data, ack in
            if staging {
                print ("received endpoint ready")
            }
            let isPjsuaUp: Bool = Singleton.shared.getPjsipStatus()
            if isPjsuaUp == false{
                let num: String = cc + phone
                let status = self.pjsipInstance.start(num, withHost: Singleton.shared.getHost(), withMode: staging)
                if (status == "SUCCESS") {
                    Singleton.shared.setPjsipStatus(status: true)
                    self.callVoipTimer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(PatchCallScreen.voipTimer)), userInfo: nil, repeats: true)
                    if staging {
                        print("Pjsua started")
                    }
                } else {
                    Singleton.shared.setPjsipStatus(status: false)
                    if staging {
                        print("pjsua registeration failed")
                    }
                    //
                }
            }
        }
        socket?.connect()
    }
    
    func onDecline() {
        if staging {
            print("call declined function is called in patch call screen")
        }
        callStatus.text = "Declined"
        player?.stop()
        self.declineTimer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(PatchCallScreen.startDeclineTimer)), userInfo: nil, repeats: true)
    }
    
    func onMissed() {
        if staging {
            print("call missed function is called in patch call screen")
        }
        callStatus.text = "missed"
        player?.stop()
        self.declineTimer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(PatchCallScreen.startDeclineTimer)), userInfo: nil, repeats: true)
    }
    
    func initCallSock(callContext: String, call: String) {
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        if call == "incoming" {
            NotificationCenter.default.addObserver(self, selector: #selector(self.messagereceived(notification:)), name: NSNotification.Name(rawValue: "MessageReceived"), object: nil)
            self.callType = "incoming"
            callLabel.text = callContext
            callManager = PatchDelegate.callManager
            onAnswer()
        } else {
            if Singleton.shared.getIsPstn() == true {
                callLabel.text = callContext
                callManager = PatchDelegate.callManager
                onAnswer()
            } else {
                speaker.isHidden = true
                mute.isHidden = true
                self.callTimer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(PatchCallScreen.callingTimer)), userInfo: nil, repeats: true)
                timerLabel.isHidden = true
                NotificationCenter.default.addObserver(self, selector: #selector(self.messagereceived(notification:)), name: NSNotification.Name(rawValue: "MessageReceived"), object: nil)
                callLabel.text = callContext
                callManager = PatchDelegate.callManager
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    self.startOutgoingTone()
                })
            }
            
            //            self.outgoingToneTimer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(PatchCallScreen.startOutgoingToneTimer)), userInfo: nil, repeats: true)
        }
    }
    
    func startOutgoingTone() {
        guard let url = Bundle.main.url(forResource: "outgoing_tone", withExtension: "mp3") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
            try AVAudioSession.sharedInstance().setActive(true)
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            //                guard let player = player else { return }
            player?.currentTime = (player?.duration)! + (player?.duration)!
            player?.prepareToPlay()
            player?.play()
            player?.numberOfLoops = 1
            if staging {
                print("Audio started")
            }
        } catch let error {
            if staging {
                print(error.localizedDescription)
            }
        }
    }
    
    @objc func messagereceived(notification:Notification)
    {
        let message = notification.object as? String
        //        print("event received message is----->\(String(describing: message))")
        if message == "decline" {
            onDecline()
        } else if message == "answer" {
            if staging {
                print("answering the call")
            }
            self.isCallAnswered = true
            onAnswer()
        } else if message == "cancel" {
            close()
        } else if message == "endCall" {
            closeCallkit()
        } else {
            onMissed()
        }
    }
    
    @objc func startDeclineTimer() {
        declineSeconds -= 1
        if declineSeconds == 0 {
            close()
            self.removeFromSuperview()
            declineTimer.invalidate()
        }
    }
    
    @objc func startOutgoingToneTimer() {
        outgoingSeconds -= 1
        if outgoingSeconds == 0 {
            
        }
    }
    
    @objc func callingTimer() {
        callingSeconds -= 1
        if callingSeconds == 0 {
            close()
            //            self.removeFromSuperview()
            callTimer.invalidate()
        }
    }
    
    @objc func voipTimer() {
        sec -= 1
        if sec == 0 {
            //            print("call me voip","")
            socket?.emitWithAck("call_voip","").timingOut(after: 20) { data in
                //                print("data in call voip \(data)")
                guard let callVoipData = data[0] as? NSDictionary else {
                    return
                }
                guard let status: Bool = callVoipData["status"] as? Bool else {
                    return
                }
                if status {
                    self.player?.stop()
                    if staging {
                        print("ack of call voip recieved")
                    }
                    if Singleton.shared.getIsPstn() == true {
                        let callPstndata: [String: Any] = [
                            "cc": Singleton.shared.calleeCC,
                            "phone": Singleton.shared.calleePhone,
                        ]
                        self.socket?.emitWithAck("call_pstn", callPstndata).timingOut(after: 5, callback: { (data) in
                            if staging {
                                print("pstn call is made to \(callPstndata)")
                            }
                        })
                    }
                    
                    
                } else {
                    self.close()
                }
            }
            callVoipTimer.invalidate()
        }
    }
    
    @IBAction func close() {
        let call = Call(uuid: Singleton.shared.getUUID(), handle: Singleton.shared.getHandle())
        callManager.end(call: call)
        if self.callType != "incoming" && self.isCallAnswered == false {
            if staging {
                print("cancelling this call")
            }
            ss?.cancel(callID: Singleton.shared.getCallId())
        }
        
        let pjsipstatus: Bool  = Singleton.shared.getPjsipStatus()
        if staging {
            print("pjsip status is \(pjsipstatus)")
        }
        if pjsipstatus == true {
            pjsipInstance.stop()
            Singleton.shared.setPjsipStatus(status: false)
        }
        Singleton.shared.setIsPSTN(isPstn: false)
        Singleton.shared.setCalleePhone(phone: "")
        Singleton.shared.setCalleeCc(cc: "")
        Singleton.shared.setCallId(callId: "")
        player?.stop()
        player = nil
        stopAudio()
        NotificationCenter.default.removeObserver(self)
        if staging {
            print("disconnecting callsock")
        }
        if (!self.alone) {
            self.socket?.emit("hangup")
        }
        self.socket?.removeAllHandlers()
        self.socket?.disconnect()
        timer.invalidate()
        self.removeFromSuperview()
    }
    
    func closeCallkit() {
        if staging {
            print("cancelling the call from callkit")
        }
        if self.callType != "incoming" && self.isCallAnswered == false {
            if staging {
                print("cancelling this call")
            }
            ss?.cancel(callID: Singleton.shared.getCallId())
        }
        let pjsipstatus: Bool  = Singleton.shared.getPjsipStatus()
        if pjsipstatus == true {
            pjsipInstance.stop()
            Singleton.shared.setPjsipStatus(status: false)
        }
        Singleton.shared.setIsPSTN(isPstn: false)
        Singleton.shared.setCalleePhone(phone: "")
        Singleton.shared.setCalleeCc(cc: "")
        Singleton.shared.setCallId(callId: "")
        player?.stop()
        player = nil
        stopAudio()
        NotificationCenter.default.removeObserver(self)
        Singleton.shared.setPjsipStatus(status: false)
        if (!self.alone) {
            self.socket?.emit("hangup")
        }
        self.socket?.removeAllHandlers()
        self.socket?.disconnect()
        self.removeFromSuperview()
        timer.invalidate()
    }
    
    
    
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(PatchCallScreen.updateTimer)), userInfo: nil, repeats: true)
        //        print(timer)
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
    
    @IBAction func speakerHandler() {
        if self.speakerStatus == false {
            pjsipInstance.speakeron()
            self.speakerStatus = true
        } else if self.speakerStatus == true {
            pjsipInstance.speakeroff()
            self.speakerStatus = false
        }
    }
    
    @IBAction func muteHandler() {
        if self.muteStatus == false {
            pjsipInstance.mute()
            self.muteStatus = true
        } else if self.muteStatus == true {
            pjsipInstance.unmute()
            self.muteStatus = false
        }
    }
}
