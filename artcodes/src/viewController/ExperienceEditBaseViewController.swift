//
//  ExperienceEditInfoViewController.swift
//  artcodes
//
//  Created by Kevin Glover on 04/08/2015.
//  Copyright (c) 2015 Horizon. All rights reserved.
//

import Foundation
import artcodesScanner

class ExperienceEditBaseViewController: ArtcodeViewController
{
	var experience: Experience!
	
	var name: String
	{
		return "Base"
	}
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		// Do any additional setup after loading the view.
	}
	
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	
}
