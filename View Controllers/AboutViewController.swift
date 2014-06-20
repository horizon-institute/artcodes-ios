//
//  AboutViewController.swift
//  aestheticodes
//
//  Created by Kevin Glover on 09/06/2014.
//  Copyright (c) 2014 horizon. All rights reserved.
//

import Foundation
import UIKit

class AboutViewController : UIViewController
{
	@IBOutlet var aboutView: UIWebView
	
	override func viewDidLoad()
	{
		let url = NSBundle.mainBundle().URLForResource("about", withExtension: "html")
		aboutView.loadRequest(NSURLRequest(URL: url))
		
		super.viewDidLoad();
	}
}