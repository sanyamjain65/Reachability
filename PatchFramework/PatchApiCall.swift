//
//  PatchApiCall.swift
//  PatchSdk
//
//  Created by Sanyam Jain on 15/09/18.
//  Copyright © 2018 Sanyam Jain. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import SwiftyJSON
import PatchFrameworkPrivate


public class PatchApiCall {
//    static var sigsockInstance: Sigsock? = Sigsock()
//    var VC: UIViewController! = nil

    
    public static func makeCall(viewController: UIViewController,withContext callContext: String) {
        PatchDelegate.callManager.startCall(handle: callContext, videoEnabled: false)
    }
    
    public static func initSDK(withAccountId accountId: String, withApiKey apiKey: String, withName name: String, withCC cc: String, withPhone phone: String, completion: @escaping(String?, String?) -> ()) {
        var components = URLComponents(string: APIEndpoint.url() + "api/accounts/\(accountId)/apikeys")!
        var items = [URLQueryItem]()
        items.append(URLQueryItem(name: "where", value: ["value":"\(apiKey)"] as? String))
        components.queryItems = items
        var urlRequest = URLRequest(url: components.url!)
        urlRequest.httpMethod = "GET"
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: urlRequest as URLRequest, completionHandler: { data, response, error in
            guard error == nil else {
                return
            }
            
            guard let data = data else {
                return
            }
            
            do {
                //create json object from data
                if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [[String: Any]] {
                    print(json)
                    let res = json[0]
                    let id = res["id"]
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
                    print("id is \(String(describing: id))")
                }
                
            } catch let error {
                print(error.localizedDescription)
            }
        })
        task.resume()
    }
    
    public static func registerContact(withPhone phone: String, withCC cc: String, withName name: String, withAccountId accountId: String, completion: @escaping(String?, String?) -> ()) {
        let session = URLSession.shared
        let url = URL(string: APIEndpoint.url() + "api/accounts/\(accountId)/contacts")
        print("cc is \(cc), phone is \(phone), name is \(name)")
        let postData = "cc=\(cc)&phone=\(phone)&name=\(name)&accountId=\(accountId)&pushtoken_ios=\(PatchDelegate.voipToken)".data(using: .utf8)
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.httpBody = postData
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            guard error == nil else {
                completion(nil, "failed")
                return
            }
            guard let data = data else {
                completion(nil, "failed")
                return
            }
            do {
                //create json object from data
                if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: Any] {
                    print("user after registration is \(json)")
                    let name = json["name"]
                    let cc = json["cc"]
                    let phone = json["phone"]
                    let id = json["id"]
                    print("id is\(String(describing: id)), name is \(String(describing: name)), phone is \(String(describing: phone)), cc is \(String(describing: cc))")
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
            } catch let error {
                print(error.localizedDescription)
                completion(nil, "failed")
            }
        })
        task.resume()
    }
    
    public static func getToken(withAccountId accountId: String, withCC cc: String, withPhone phone: String, completion: @escaping(_ response: String?, _ error: String?) -> ()) {
        
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
                //create json object from data
                if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: Any] {
                    print(json)
                    let jwtToken = json["token"]
                    print("jwt token is \(String(describing: jwtToken))")
                    if(jwtToken == nil) {
                        completion(nil, "token cannot be fetched")
                    } else {
                        completion("token is fetched successfully",nil)
                    }
                }
            } catch let error {
                completion(nil, "token cannot be fetched")
                print(error.localizedDescription)
            }
        })
        task.resume()
    }
//
//    func setDeviceToken(cc: String, phone: String, name: String, contactID: String, completion: @escaping(String?, String?) -> ()) {
//        let session = URLSession.shared
//        let url = URL(string: APIEndpoint.url() + "api/contacts/\(contactID)")
//        print("cc is \(cc), phone is \(phone), name is \(name)")
//        let postData = "cc=\(cc)&phone=\(phone)&name=\(name)&pushtoken_ios=\(PatchDelegate.voipToken)&id=\(contactID)".data(using: .utf8)
//        var request = URLRequest(url: url!)
//        request.httpMethod = "PATCH"
//        request.httpBody = postData
//
//        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
//            guard error == nil else {
//                completion(nil, "failed")
//                return
//            }
//            guard let data = data else {
//                completion(nil, "failed")
//                return
//            }
//            do {
//                //create json object from data
//                if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: Any] {
//                    print(json)
//                    print("device token is successfully set")
//                    completion("device token is successfully set in user", nil)
//                }
//            } catch let error {
//                print(error.localizedDescription)
//                completion(nil, "failed")
//            }
//        })
//        task.resume()
//    }
    
}
