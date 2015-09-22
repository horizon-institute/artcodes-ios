//
//  RecommendedViewController.swift
//  artcodes
//
//  Created by Kevin Glover on 04/08/2015.
//  Copyright (c) 2015 Horizon. All rights reserved.
//

import Foundation
import artcodesScanner

class RecommendedViewController: ExperienceTableViewController
{
    override var ordering: [String]
    {
        return ["recent", "nearby", "featured", "new", "popular"]
    }
    
    override init()
    {
		super.init(nibName:"RecommendedViewController", bundle:nil)        
    }

    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
	override func viewDidLoad()
	{
		super.viewDidLoad()
        
        screenName = "View Recommended"
		
		server.loadRecommended { (experiences) -> Void in
            self.progressView.stopAnimating()
			for (key, experienceURIs) in experiences
			{
				self.addExperienceURIs(experienceURIs, forGroup: key)
			}
			self.tableView.reloadData()
		}
	}
}