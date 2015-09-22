//
//  AppEngineAccount.swift
//  artcodes
//
//  Created by Kevin Glover on 03/08/2015.
//  Copyright (c) 2015 Horizon. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class AppEngineAccount: Account
{
    var email: String
    var token: String
    var name: String
    {
        return email
    }
    
    var id: String
    {
        return "google:\(email)"
    }
    
    init(email: String, token: String)
    {
        self.email = email
        self.token = token
    }
    
    func loadLibrary(closure: ([String]) -> Void)
    {
        let headers = [
            "Authorization": "Bearer \(token)"
        ]
        
        // TODO
        Alamofire.request(.GET, "https://aestheticodes.appspot.com/experiences", headers: headers).response { (request, response, data, error) -> Void in
            if let jsonData = data
            {
                let result = JSON(data: jsonData).arrayValue.map { $0.string!}
                closure(result)
            }
        }
    }
}