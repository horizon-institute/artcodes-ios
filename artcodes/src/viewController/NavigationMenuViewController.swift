//
//  NavigationTableViewController.swift
//  artcodes
//
//  Created by Kevin Glover on 03/09/2015.
//  Copyright (c) 2015 Horizon. All rights reserved.
//

import Foundation
import DrawerController

class NavigationMenuViewController: ArtcodeViewController, UITableViewDataSource, UITableViewDelegate, GIDSignInUIDelegate
{
	let identifier = "NavigationMenuViewCell"
	
	let navigation: [String] = ["recommended", "starred"]
	let icons = ["recommended": "ic_photo_camera_18pt", "starred": "ic_star_18pt"]
	var drawerController: DrawerController!
	
	@IBOutlet weak var tableView: UITableView!
	
    init()
	{
		super.init(nibName:"NavigationMenuViewController", bundle:nil)
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
	}
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		let nibName = UINib(nibName: identifier, bundle:nil)
		tableView.registerNib(nibName, forCellReuseIdentifier: identifier)
		
		tableView.selectRowAtIndexPath(NSIndexPath(forItem: 0, inSection: 0), animated: false, scrollPosition: UITableViewScrollPosition.Top)
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		if section == 0
		{
			return navigation.count
		}
        if server.accounts.count > 1
        {
            return server.accounts.count
        }
		return server.accounts.count + 1
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		let cell :NavigationMenuViewCell = tableView.dequeueReusableCellWithIdentifier(identifier) as! NavigationMenuViewCell
		if indexPath.section == 0
		{
			let item = navigation[indexPath.item]
			let itemTitle = NSLocalizedString(item, tableName: nil, bundle: NSBundle.mainBundle(), value: item.capitalizedString, comment: "")
			
			cell.navigationTitle.text = itemTitle
			
			if let icon = icons[item]
			{
				cell.navigationIcon.image = UIImage(named: icon)
			}
		}
		else
		{
			if indexPath.item == server.accounts.count
			{
				cell.navigationTitle.text = "Add Account"
				cell.navigationIcon.image = UIImage(named: "ic_add_18pt")
			}
            else
            {
                let account = server.accounts[indexPath.item]
                cell.navigationTitle.text = account.name
            }
		}
		return cell;
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
	{
		if let vc = createViewController(indexPath)
		{
			drawerController.setCenterViewController(vc, withCloseAnimation: true, completion: nil)
		}
		else if indexPath.section == 1 && indexPath.item == server.accounts.count
		{
            GIDSignIn.sharedInstance().uiDelegate = self
            GIDSignIn.sharedInstance().signIn()
			// Add account
		}
	}
	
	func createViewController(indexPath: NSIndexPath) -> UIViewController?
	{
		if indexPath.section == 0
		{
			if indexPath.item == 0
			{
				let vc = RecommendedViewController()
				vc.server = server
				return vc
			}
			else if indexPath.item == 1
			{
				// TODO Create starred view controller
			}
		}
		else if indexPath.section == 1
		{
			// Create library view controller
            let vc = AccountViewController(account: server.accounts[indexPath.item])
            vc.server = server
            return vc
		}
		return nil
	}
	
	func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
	{
		if section == 0
		{
			return nil
		}
		else
		{
			return NSLocalizedString("libraries", tableName: nil, bundle: NSBundle.mainBundle(), value: "Libraries", comment: "")
		}
	}
	
	func numberOfSectionsInTableView(tableView: UITableView) -> Int
	{
		return 2
	}
}