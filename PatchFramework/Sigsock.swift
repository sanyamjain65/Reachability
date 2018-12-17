import SocketIO

class Sigsock {
    var  manager: SocketManager? = nil
    var socket: SocketIOClient? = nil
    let jwt: String = Singleton.shared.getJwtToken()
    var callId: String = ""
    var sid: String = ""
    var initiatorId: String = ""
    var sna: String = ""
    
    func initSigsock(withphone phone:String, withcc cc: String, withAccountId accountId: String) {
        getToken(withAccountId: accountId, withCC: cc, withPhone: phone) { (res, err) in
            if res != nil {
                self.startSigsock()
            } else {
                print("Server Error. Please restart your app")
            }
        }
    }
    
    func startSigsock() {
        if staging {
            print("connecting sigsock")
        }
        let preferences  = UserDefaults.standard
        let cc = preferences.object(forKey: "cc")
        let phone = preferences.object(forKey: "phone")
        let apikey = preferences.object(forKey: "apikey")
        let accountId = preferences.object(forKey: "accountId")
        let authData: [String: Any] = [
            "platform": "ios",
            "apikey": apikey,
            "accountId": accountId,
            "cc": cc,
            "phone": phone
        ]
        if staging {
            manager = SocketManager(socketURL:  URL(string: "https://" + sna)!, config:[.log(true),.forceNew(true),.reconnectAttempts(5),.reconnectWait(6000),.connectParams(["jwt": Singleton.shared.getJwtToken()]),.forceWebsockets(true),.compress])
        } else {
            manager = SocketManager(socketURL:  URL(string: "https://" + sna)!, config:[.forceNew(true),.reconnectAttempts(5),.reconnectWait(6000),.connectParams(["jwt": Singleton.shared.getJwtToken()]),.forceWebsockets(true),.compress])
        }
        socket = manager?.defaultSocket
        socket?.on(clientEvent: .connect) {data, ack in
            if staging {
                print("socket connected")
            }
        }
        socket?.on(clientEvent: .disconnect) {data, ack in
            if staging {
                print("server disconnected")
                print(data)
            }
        }
        //        socket?.on(clientEvent: .error) {data, ack in
        ////            print("socket error")
        ////            print(data)
        //        }
        //        socket?.on(clientEvent: .statusChange) {data, ack in
        ////            print("socket status change")
        ////            print(data)
        //        }
        socket?.on("connect") { data, ack in
            if staging {
                print ("auth data is \(authData)")
            }
            self.socket?.emit("authentication", authData)
        }
        socket?.on("cancel") { data, ack in
            let dataArray = data as NSArray
            guard let cancelCall = dataArray[0] as? String else {
                return
            }
            if staging {
                print(" data on cancel is \(cancelCall)")
            }
            let currentCall = Singleton.shared.getCallId()
            if (currentCall == "") {
                let answer_ack: String = "noactivecall"
                ack.with(answer_ack)
            } else if (currentCall != cancelCall) {
                let answer_ack: String = "othercall"
                ack.with(answer_ack)
            } else {
                NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "MessageReceived"),object: "cancel"))
                let answer_ack: [String: Any] = [
                    "status": true
                ]
                ack.with(answer_ack)
            }
        }
        socket?.on("authenticated") { data, ack in
            if staging {
                print("sigsock authenticated")
                print(data)
            }
            //
            Singleton.shared.setIsSigsockRunning(isSigsockRunning: true)
            print("server connected")
        }
        socket?.on("answer") { data, ack in
            if staging {
                print("received answer")
            }
            let answer_ack: [String: Any] = [
                "status": true
            ]
            ack.with(answer_ack)
            NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "MessageReceived"),object: "answer"))
            //            print(data)
        }
        socket?.on("decline") { data, ack in
            if staging {
                print("received decline")
            }
            let decline_ack: [String: Any] = [
                "status": true
            ]
            ack.with(decline_ack)
            NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "MessageReceived"),object: "decline"))
            //            print(data)
        }
        socket?.on("miss") { data, ack in
            if staging {
                print("received miss")
            }
            let miss_ack: [String: Any] = [
                "status": true
            ]
            ack.with(miss_ack)
            NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "MessageReceived"),object: "miss"))
            //            print(data)
        }
        
        socket?.on("incoming_call") { data, ack in
            if staging {
                print("recieved incoming call event")
                print(data)
            }
            do {
                let incoming_ack: [String: Any] = [
                    "status": true
                ]
                ack.with(incoming_ack)
                let dataArray = data as NSArray
                guard let dataString = dataArray[0] as? NSDictionary else {
                    return
                }
                if staging {
                    print(dataString)
                }
                guard let context = dataString["context"] as? String else {
                    print("Server error while receiving a call")
                    return}
                guard let callId = dataString["call"] as? String else {
                    print("Server error while receiving a call")
                    return}
                guard let host = dataString["host"] as? String else {
                    print("Server error while receiving a call")
                    return}
                guard let sid = dataString["sid"] as? String else {
                    print("Server error while receiving a call")
                    return}
                guard let initiator = dataString["from"] as? NSDictionary else {
                    print("Server error while receiving a call")
                    return}
                guard let initiatorId = initiator["id"] as? String else {
                    print("Server error while receiving a call")
                    return}
                Singleton.shared.setHost(host: host)
                let backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now()) {
                    Singleton.shared.setHandle(handle: context)
                    Singleton.shared.setSid(sid: sid)
                    Singleton.shared.setCallId(callId: callId)
                    Singleton.shared.setInitiatorId(initiatorId: initiatorId)
                    
                    PatchDelegate.displayIncomingCall(uuid: UUID(), handle: context, hasVideo: false) { _ in
                        UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
                    }
                }
            } catch {
                if staging {
                    print("Error JSON: \(error)")
                }
            }
        }
        socket?.connect()
        
    }
    
    func makeCall(withCC cc: String, withPhone phone: String, withContext context: String, tags: [String], isPstn pstn: Bool ,completion: @escaping(String?, String?) -> ()) {
        if staging {
            print("trying to make a call.....")
        }
        let personToCall: [String: Any] = [
            "cc":cc,
            "phone": phone,
            "pstn": pstn,
            "context": context
        ]
        socket?.emitWithAck("makecall", personToCall).timingOut(after: 20) {data in
            if staging {
                print("data in make call is \(data)")
            }
            guard let makeCallAck = data[0] as? NSDictionary else {
                print("Server error while making a call.")
                completion(nil, "Server error while making a call.")
                return}
            guard let responseData = makeCallAck["data"] as? NSDictionary else {
                print("Server error while making a call.")
                completion(nil, "Server error while making a call.")
                return}
            guard let call = responseData["call"] as? String else {
                print("Server error while making a call.")
                completion(nil, "Server error while making a call.")
                return}
            guard let host = responseData["host"] as? String else {
                print("Server error while making a call.")
                completion(nil, "Server error while making a call.")
                return}
            guard let initiatorData = responseData["from"] as? NSDictionary else {
                print("Server error while making a call.")
                completion(nil, "Server error while making a call.")
                return}
            guard let initiator = initiatorData["id"] as? String else{
                print("Server error while making a call.")
                completion(nil, "Server error while making a call.")
                return}
            if pstn == true {
                Singleton.shared.setIsPSTN(isPstn: true)
                Singleton.shared.setCalleeCc(cc: cc)
                Singleton.shared.setCalleePhone(phone: phone)
            } else {
                Singleton.shared.setIsPSTN(isPstn: false)
            }
            
            Singleton.shared.setHost(host: host)
            Singleton.shared.setCallId(callId: call)
            Singleton.shared.setInitiatorId(initiatorId: initiator)
            //            Singleton.shared.setSid(sid: sid)
            if staging {
                print("make call ack is \(makeCallAck)\n responsedata is \(responseData)\n call id is\(call)\ninitiator id is\(initiator)")
            }
            if makeCallAck["status"] as! Int == 1 {
                completion("call generated successfully", nil)
            } else {
                completion(nil, "error in generating call")
            }
        }
    }
    func answer(initiatorId: String, accountId: String, callId: String, sid: String) {
        if staging {
            print("calling answer")
        }
        let data: [String: Any] = [
            "responseSid": initiatorId + "_" + accountId,
            "callId": callId,
            "sid":sid
        ]
        socket?.emitWithAck("answer", data).timingOut(after: 5, callback: { (data) in
            print("call is answered")
        })
    }
    func decline(initiatorId: String, accountId: String, callId: String, sid: String) {
        if staging {
            print("calling decline")
        }
        let data: [String: Any] = [
            "responseSid": initiatorId + "_" + accountId,
            "callId": callId,
            "sid":sid
        ]
        socket?.emitWithAck("decline", data).timingOut(after: 5, callback: { (data) in
            print("call is declined")
        })
    }
    func miss(initiatorId: String, accountId: String, callId: String, sid: String) {
        if staging {
            print("calling miss")
        }
        let data: [String: Any] = [
            "responseSid": initiatorId + "_" + accountId,
            "callId": callId,
            "sid":sid
        ]
        socket?.emitWithAck("miss", data).timingOut(after: 5, callback: { (data) in
            print("call is missed")
        })
    }
    
    func cancel(callID: String) {
        socket?.emitWithAck("cancel", callID).timingOut(after: 5, callback: { (data) in
            print("call is cancelled")
        })
    }
    
    func getToken(withAccountId accountId: String, withCC cc: String, withPhone phone: String, completion: @escaping(_ response: String?, _ error: String?) -> ()) {
        
        var components = URLComponents(string: APIEndpoint.url() + "api/contacts/jwt")!
        var items = [URLQueryItem]()
        items.append(URLQueryItem(name: "cc", value: cc))
        items.append(URLQueryItem(name: "phone", value: phone))
        items.append(URLQueryItem(name: "accountId", value: accountId))
        components.queryItems = items
        var urlRequest = URLRequest(url: components.url!)
        urlRequest.httpMethod = "GET"
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: urlRequest as URLRequest, completionHandler: { data, response, error in
            guard error == nil else {
                completion(nil, "token cannot be fetched")
                return
            }
            guard let data = data else {
                completion(nil, "token cannot be fetched")
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: Any] {
                    if staging {
                        print("response of jet token is \(json)")
                    }
                    guard let jwtToken = json["token"] else {
                        completion(nil,"token cannot be fetched")
                        return}
                    guard let sna = json["sna"] as? String else {
                        completion(nil, "sna cannot be fetched")
                        return
                    }
                    self.sna = sna
                    if staging {
                        print("sna is \(self.sna)")
                        print("jwt token is \(String(describing: jwtToken))")
                    }
                    if(jwtToken == nil) {
                        completion(nil, "token cannot be fetched")
                    } else {
                        Singleton.shared.setJwtToken(token: jwtToken as! String)
                        completion("token is fetched successfully",nil)
                    }
                }
            } catch let error {
                completion(nil, "token cannot be fetched")
                if staging {
                    print(error.localizedDescription)
                }
            }
        })
        task.resume()
    }
}
