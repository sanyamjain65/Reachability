//
//  PatchApiCall.swift
//  PatchSdk
//
//  Created by Sanyam Jain on 15/09/18.
//  Copyright © 2018 Sanyam Jain. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import PatchFrameworkPrivate

public class PatchApiCall {
//    static var sigsockInstance: Sigsock? = Sigsock()

    
    public static func makeCall(withContext callContext: String) {
        let patchDelegate = PatchDelegate()
        patchDelegate.makeCall(withContext: callContext)
    }
    
    public static func initSDK(withAccountId accountId: String, withApiKey apiKey: String, withName name: String, withCC cc: String, withPhone phone: String, completion: @escaping(String?, String?) -> ()){
//        let x = Sigsock()
//        x.startSigsock()
//        PatchApiCall.sigsockInstance?.initSigsock()
        if ((phone == "" || phone == nil) ||
            (cc == "" || cc == nil) ||
            (accountId == "" || accountId == nil) ||
            (apiKey == "" || apiKey == nil) ||
            (name == "" || name == nil)) {
            completion(nil,"Please pass the correct parameters")
        } else {
            let parameters: Parameters = [
                "where": ["value":"\(apiKey)"]
            ]
            Alamofire.request(APIEndpoint.url() + "api/accounts/\(accountId)/apikeys", method: .get, parameters: parameters, headers: nil).responseJSON(completionHandler: {(response) -> Void  in
                if response.result.isSuccess {
                    let resJson = JSON(response.result.value!)
                    let id = resJson[0]["id"].string
                    if id != nil {
                        self.registerContact(withPhone: phone, withCC: cc, withName: name, withAccountId: accountId, completion: { (res, err) in
                            if res != nil {
                                self.getToken(withAccountId: accountId, withCC: cc, withPhone: phone, completion: { (res, err) in
                                    if res != nil {
                                        completion("sdk is successgully initialized",nil)
                                    } else {
                                        completion(nil, "problem with user registration")
                                    }
                                })
                            } else {
                                completion(nil, "problem with user registration")
                            }
                        })
                    } else {
                        completion(nil,"something went wrong")
                    }
                }
                if response.result.isFailure {
                    let error : Error = response.result.error!
                    completion(nil, error as? String)
                }
            })
        }
    }
    
    static func registerContact(withPhone phone: String, withCC cc: String, withName name: String, withAccountId accountId: String, completion: @escaping(_ response:String?, _ error: String?) -> ()) {
        let parameters: Parameters = [
            "cc": cc,
            "phone": phone,
            "name": name
        ]
        Alamofire.request(APIEndpoint.url() + "api/accounts/\(accountId)/contacts", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            if response.result.isSuccess {
                let resJson = JSON(response.result.value!)
                let name = resJson["name"].string
                let cc = resJson["cc"].string
                let phone = resJson["phone"].string
                let id = resJson["id"].string
                let preferences = UserDefaults.standard
                preferences.set(name, forKey: "name")
                preferences.set(cc, forKey: "cc")
                preferences.set(phone, forKey: "phone")
                preferences.set(id, forKey: "id")
                let didSave = preferences.synchronize()
                if didSave{
                    print("user deatils are successfuly stored in user defaults")
                } else {
                    print("problem storing user details in user defaults")
                }
                completion("user is successfully registered", nil)
            }
            if response.result.isFailure {
                let error : Error = response.result.error!
                completion(nil, error as? String)
            }
        }
    }
    
    static func getToken(withAccountId accountId: String, withCC cc: String, withPhone phone: String, completion: @escaping(_ response: String?, _ error: String?) -> ()) {
        
        let parameters: Parameters = [
            "cc": cc,
            "phone": phone,
            "accountId": accountId
        ]
        
        Alamofire.request(APIEndpoint.url() + "api/contacts/jwt", method: .get, parameters: parameters, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            if response.result.isSuccess {
                let resJson = JSON(response.result.value!)
                let token = resJson["token"].string
                if(token == nil || token == "") {
                    completion(nil, "token cannot be fetched")
                } else {
                    completion("token is fetched successfully",nil)
                }
            }
            if response.result.isFailure {
                let error : Error = response.result.error!
                completion(nil, error as? String)
            }
        }
    }
    
}
