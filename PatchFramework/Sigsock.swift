import SocketIO

class Sigsock {
    var  manager: SocketManager? = nil
    var socket: SocketIOClient? = nil
    let patchDelegate = PatchDelegate()
    
    func startSigsock() {
        print("connecting sigsock")
        let authData: [String: Any] = [
            "platform": "ios",
            "accountId": "5bae188f57ee34064b739b56",
            "apikey": "test123",
            "cc": "91",
            "phone": "7042437761"
        ]
        manager = SocketManager(socketURL:  URL(string: "http://13.232.251.218:9476")!, config:[.log(true), .forceNew(true),.reconnectAttempts(5),.reconnectWait(6000),.connectParams(["jwt":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE1Mzg0NjE2NzMsImNpZCI6IjViYWUxYjRiNzgyMDQ2MWU3MGZiM2U3YyIsImFpZCI6IjViYWUxODhmNTdlZTM0MDY0YjczOWI1NiIsImlhdCI6MTUzODM3NTI3MywiaXNzIjoiUGF0Y2hVUyBDb21tdW5pY2F0aW9ucyBQdnQuIEx0ZC4ifQ.Il9aaH7BV67gh86sA-D3rjPELnrEMtPzldl2goEJVu8"]),.forceWebsockets(true),.compress])
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
        socket?.on("connect") { data, ack in
            print ("auth data is \(authData)")
            self.socket?.emit("authentication", authData)
        }
        socket?.on("authenticated") { data, ack in
            print(data)
        }
        socket?.on("incoming_call") { data, ack in
            print(data)
            do {
//                let bundle = Bundle(for: Sigsock.self)
                let dataArray = data as NSArray
                let dataString = dataArray[0] as! NSDictionary
                print(dataString)
                let context = dataString["context"] as! String
                let backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now()) {
                    PatchDelegate.displayIncomingCall(uuid: UUID(), handle: context, hasVideo: false) { _ in
                        UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
                    }
                }
//                self.patchDelegate.openIncomingCallkitScreen(withContext: context)
            } catch {
                print("Error JSON: \(error)")
            }
        }
        socket?.connect()
    }
    
    func makeCall(withCC cc: String, withPhone phone: String) {
        let personToCall: [String: Any] = [
            "cc":"91",
            "phone": "9650173677",
            "pstn": false
        ]
        socket?.emit("makecall", personToCall)
    }
}
