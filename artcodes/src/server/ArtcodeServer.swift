//
//  ArtcodeServer.swift
//  artcodes
//
//  Created by Kevin Glover on 11/08/2015.
//  Copyright (c) 2015 Horizon. All rights reserved.
//

import Foundation
import artcodesScanner

protocol ArtcodeServer
{
    var accounts: [Account] { get }
    
	func loadRecommended(closure: ([String: [String]]) -> Void)
	func loadExperience(uri: String, closure: (Experience) -> Void)
}