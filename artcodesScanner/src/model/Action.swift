//
//  Action.swift
//  artcodes
//
//  Created by Kevin Glover on 31/07/2015.
//  Copyright (c) 2015 Horizon. All rights reserved.
//

import Foundation

public enum Match
{
	case any
	case all
	case sequence
}

public class Action
{
	public var name: String?
	public var url: String?
	public var codes = [String]()
	public var match = Match.any
	public var description: String?
	public var image: String?
	public var showDetail = false
}