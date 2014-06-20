//
//  Marker.swift
//  aestheticodes
//
//  Created by Kevin Glover on 09/06/2014.
//  Copyright (c) 2014 horizon. All rights reserved.
//

import Foundation

class Marker: NSObject
{
	var code: Int[] = []
	var nodeIndices: Int[] = []
	var codeKey: String
	{
		get
		{
			var codeStr = ""
			
			for i in 0..code.count
			{
				if (i > 0)
				{
					codeStr += ":\(code[i])"
				}
				else
				{
					codeStr += "\(code[i])"
				}
			}
			
			return codeStr
		}
	}
	
	var emptyRegionCount: Int
	{
		var emptyRegions = 0;
		
		for leaf in code
		{
			if (leaf == 0)
			{
				emptyRegions++;
			}
		}
		return emptyRegions;
	}
	
	func addNode(node: Int)
	{
		nodeIndices += node
	}
}