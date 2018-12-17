//
//  PatchApiCall.swift
//  PatchSdk
//
//  Created by Sanyam Jain on 15/09/18.
//  Copyright © 2018 Sanyam Jain. All rights reserved.
//

import Foundation
import UIKit
import PatchFrameworkPrivate


public class PatchApiCall {
    static var sigsockInstance: Sigsock? = Sigsock()
    static var patchDelegate = PatchDelegate()
    
    
    public static func makeCall(withCC cc: String, withPhone phone:String,withContext callContext: String, isPstn pstn: Bool, tags: [String], completion: @escaping(String?, String?) -> ()) {
        if tags.count > 0 {
            if tags.count > 10 {
//                if staging {
                    print("length of tags is more than 10")
                completion(nil, "length of tags is more than 10")
//                }
                return
            }
            for (index,tagValue) in tags.enumerated() {
                if tagValue.count > 32 {
//                    if staging {
                        print("length of tag \(tagValue) at position \(index + 1) is more than 32")
                    completion(nil, "length of tag \(tagValue) at position \(index + 1) is more than 32")
                        return
//                    }
                }
            }
        } else {
//            if staging {
                print("no tags are specified")
//            }
        }
        let characterSet:NSCharacterSet = NSCharacterSet(charactersIn: "0123456789")
        if ((phone.count < 6) || (phone.count > 20) || phone.rangeOfCharacter(from: characterSet.inverted) != nil )  {
            print("Please pass the correct phone number")
            completion(nil,"Please pass the correct phone number")
            return
        }
        if (cc.count < 1 || cc.count > 4 || cc.rangeOfCharacter(from: characterSet.inverted) != nil) {
            print("Please pass the correct country code")
            completion(nil, "Please pass the correct country code")
            return
        }
        if (callContext.count > 64) {
            print("CallContext cannot be more than 64 characters long")
            completion(nil, "CallContext cannot be more than 64 characters long")
            return
        }
        PatchDelegate.sigsockInstance?.makeCall(withCC: cc, withPhone: phone, withContext: callContext, tags: tags, isPstn: pstn, completion: { (res, err) in
            if res != nil {
                PatchDelegate.callManager.startCall(handle: callContext, videoEnabled: false)
                
                completion("call placed successfully", nil)
            } else{
                if staging {
                   print(err!)
                }
                completion(nil, err!)
            }
        })
    }
    
    public static func registerVoIP(withRootView rootview: UIViewController) {
        patchDelegate.registreVoIP(withRootView: rootview)
    }
    
    public static func initSDK(withAccountId accountId: String, withApiKey apiKey: String, withName name: String, withPicture pitcure: String, withCC cc: String, withPhone phone: String, completion: @escaping(String?, String?) -> ()) {
        if ((phone.count < 6) || (phone.count > 20) || !(CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: phone))) )  {
            completion(nil, "Please pass the correct phone number")
            return
        }
        if (cc.count < 1 || cc.count > 4) {
            completion(nil, "Please pass the correct country code")
            return
        }
        if (name.count > 25) {
            completion(nil, "Name cannot be more than 25 characters long") 
            return
        }
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
                    if staging {
                        print(json)
                    }
                    let res = json[0]
                    guard let id = res["id"] else {
                        completion(nil,"something went wrong. Server error")
                        return
                    }
                    if id != nil {
//                        let preferences  = UserDefaults.standard
//                        if preferences.object(forKey: "phone") == nil {
//                            if staging {
//                               print("user is not yet registered")
//                            }
                            self.registerContact(withPhone: phone, withCC: cc, withName: name, withPitcure: pitcure, withApiKey: apiKey, withAccountId: accountId, completion: { (res, err) in
                                if res != nil {
                                     PatchDelegate.sigsockInstance?.initSigsock(withphone: phone, withcc: cc, withAccountId: accountId)
                                } else {
                                    completion(nil, "problem with user registration")
                                }
                            })
//                        } else {
//                            if staging {
//                                print("user is already registered....fetching token")
//                            }
//                            PatchDelegate.sigsockInstance?.initSigsock(withphone: phone, withcc: cc, withAccountId: accountId)
//                        }
                    } else {
                        completion(nil,"something went wrong. Please check the account credentials.")
                    }
                    if staging {
                        print("id is \(String(describing: id))")
                    }
                }
                
            } catch let error {
                if staging {
                    print(error.localizedDescription)
                }
            }
        })
        task.resume()
    }
    
    static func registerContact(withPhone phone: String, withCC cc: String, withName name: String, withPitcure picture: String, withApiKey apikey:String, withAccountId accountId: String, completion: @escaping(String?, String?) -> ()) {
        let platform = "ios"
        let session = URLSession.shared
        let url = URL(string: APIEndpoint.url() + "api/accounts/\(accountId)/contacts/signin")
        if staging {
            print("cc is \(cc), phone is \(phone), name is \(name)")
        }
        let postData = "cc=\(cc)&phone=\(phone)&name=\(name)&picure=\(picture)&pushtoken_ios=\(PatchDelegate.voipToken)&platform=\(platform)&accountId=\(accountId)&apikey=\(apikey)".data(using: .utf8)
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.httpBody = postData
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            guard error == nil else {
                completion(nil, "user registration failed")
                return
            }
            guard let data = data else {
                completion(nil, "failed")
                return
            }
            do {
                //create json object from data
                if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: Any] {
                    if staging {
                      print("user after registration is \(json)")
                    }
                    guard let name = json["name"] else{
                        completion(nil,"something went wrong. Server error")
                        return}
                    guard let cc = json["cc"] else{
                        completion(nil,"something went wrong. Server error")
                        return}
                    guard let phone = json["phone"] else{
                        completion(nil,"something went wrong. Server error")
                        return}
                    guard let branding = json["branding"] as? NSDictionary else {
                        completion(nil,"something went wrong. Server error")
                        return}
                    guard let fontColor = branding["color"] as? String else {
                        completion(nil,"something went wrong. Server error")
                        return}
                    guard let bgColor = branding["bgColor"] as? String else {
                        completion(nil,"something went wrong. Server error")
                        return}
                    guard let logo = branding["logo"] as? String else {
                        completion(nil,"something went wrong. Server error")
                        return}
                    if staging {
                        print(" font is \(String(describing: fontColor)), bgcolor is \(String(describing: bgColor)), logo is \(String(describing: logo))")
                    }
                    let preferences = UserDefaults.standard
                    preferences.set(name, forKey: "name")
                    preferences.set(cc, forKey: "cc")
                    preferences.set(phone, forKey: "phone")
                    preferences.set(accountId, forKey: "accountId")
                    preferences.set(apikey, forKey: "apikey")
                    preferences.set(fontColor, forKey: "fontColor")
                    preferences.set(bgColor, forKey: "bgColor")
                    preferences.set(logo, forKey: "logo")
                    let didSave = preferences.synchronize()
                    if didSave{
                        if staging {
                            print("user deatils are successfuly stored in user defaults")
                        }
                    } else {
                        if staging {
                            print("problem storing user details in user defaults")
                        }
                    }
                    completion("user is successfully registered", nil)
                }
            } catch let error {
                if staging {
                    print(error.localizedDescription)
                }
                completion(nil, "failed")
            }
        })
        task.resume()
    }
    
    public static func logout() {
        let preferences = UserDefaults.init()
        preferences.removeObject(forKey: "id")
        preferences.removeObject(forKey: "name")
        preferences.removeObject(forKey: "cc")
        preferences.removeObject(forKey: "phone")
        preferences.removeObject(forKey: "accountId")
        preferences.removeObject(forKey: "apikey")
        preferences.removeObject(forKey: "fontColor")
        preferences.removeObject(forKey: "bgColor")
        preferences.removeObject(forKey: "logo")
    }
}
