//
//  APIEndpoint.swift
//  PatchSdk
//
//  Created by Sanyam Jain on 15/09/18.
//  Copyright © 2018 Sanyam Jain. All rights reserved.
//

import Foundation
import Alamofire

class APIEndpoint {
    class func url() -> String {
        let url:String  = "https://gateway.patchus.in/"
        return url
    }
    
    class func headers() -> HTTPHeaders {
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "patch-api-key": "$2a$06$N7c/MWVaoBbVUtCm/HEWZutCau6wRBfbvHw5tVXpBk87tBqjsVCN6",
            "patch-client-type": "patch_charlotte"
        ]
        return headers
    }
}
