//
//  Account.swift
//  artcodes
//
//  Created by Kevin Glover on 03/08/2015.
//  Copyright (c) 2015 Horizon. All rights reserved.
//

import Foundation
import artcodesScanner

protocol Account
{
    var name: String { get }
    var id: String { get }
    
    func loadLibrary(closure: ([String]) -> Void)
}