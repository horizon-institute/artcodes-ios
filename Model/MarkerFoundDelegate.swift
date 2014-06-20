//
//  MarkerFoundDelegate.swift
//  aestheticodes
//
//  Created by Kevin Glover on 10/06/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

import Foundation

@objc protocol MarkerFoundDelegate
{
	func markersFound(markers: NSDictionary)
}