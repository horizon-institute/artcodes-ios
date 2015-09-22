//
//  LocalAccount.swift
//  artcodes
//
//  Created by Kevin Glover on 04/08/2015.
//  Copyright (c) 2015 Horizon. All rights reserved.
//

import Foundation

class LocalAccount: Account
{
    var id: String
    {
        return "local"
    }
    
    var name: String
    {
        return "Device"
    }
    
    func loadLibrary(closure: ([String]) -> Void)
    {
        
    }
}