//
//  NavigationTableViewController.swift
//  artcodes
//
//  Created by Kevin Glover on 03/09/2015.
//  Copyright (c) 2015 Horizon. All rights reserved.
//

import Foundation
import DrawerController

class AccountViewController: ExperienceTableViewController
{
    let account: Account
    
    init(account: Account)
    {
        self.account = account
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        self.account = LocalAccount()
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad()
	{
		super.viewDidLoad()
		
        screenName = "View Library"
        
        sorted = true
        
        account.loadLibrary { (experiences) -> Void in
            self.progressView.stopAnimating()
            self.addExperienceURIs(experiences, forGroup: "")
            self.tableView.reloadData()
        }
	}
}