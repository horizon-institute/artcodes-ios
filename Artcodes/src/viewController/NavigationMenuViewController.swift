/*
* Artcodes recognises a different marker scheme that allows the
* creation of aesthetically pleasing, even beautiful, codes.
* Copyright (C) 2013-2015  The University of Nottingham
*
*     This program is free software: you can redistribute it and/or modify
*     it under the terms of the GNU Affero General Public License as published
*     by the Free Software Foundation, either version 3 of the License, or
*     (at your option) any later version.
*
*     This program is distributed in the hope that it will be useful,
*     but WITHOUT ANY WARRANTY; without even the implied warranty of
*     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*     GNU Affero General Public License for more details.
*
*     You should have received a copy of the GNU Affero General Public License
*     along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import Foundation
import DrawerController

class NavigationMenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, GIDSignInUIDelegate
{
	let cellName = "NavigationMenuViewCell"
	
	var navigation = ["recommended"]
	let about = ["artcodes"]
	let icons = ["recommended": "ic_photo_camera_18pt", "recent": "ic_history_18pt", "starred": "ic_star_18pt"]
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
		
		tableView.rowHeight = UITableViewAutomaticDimension
		tableView.estimatedRowHeight = 44.0
		
		tableView.register(UINib(nibName: cellName, bundle:nil), forCellReuseIdentifier: cellName)
		tableView.selectRow(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: UITableViewScrollPosition.top)
	}
	
	override func viewWillAppear(_ animated: Bool)
	{
		navigation = ["recommended"]
		if let appDelegate = UIApplication.shared.delegate as? ArtcodeAppDelegate
		{
			
			if appDelegate.server.recent.count > 0
			{
				navigation.append("recent")
			}
			if appDelegate.server.starred.count > 0
			{
				navigation.append("starred")
			}
		}
		tableView.reloadData()
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		if section == 0
		{
			return navigation.count
		}
		else if section == 2
		{
			return about.count
		}
		else if section == 1
		{
			if let appDelegate = UIApplication.shared.delegate as? ArtcodeAppDelegate
			{
				for (_, account) in appDelegate.server.accounts
				{
					if !(account is LocalAccount)
					{
						return appDelegate.server.accounts.count
					}
				}
				return appDelegate.server.accounts.count + 1
			}
		}
		return 0
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell :NavigationMenuViewCell = tableView.dequeueReusableCell(withIdentifier: cellName) as! NavigationMenuViewCell
		if indexPath.section == 0
		{
			let item = navigation[indexPath.item]
			let itemTitle = NSLocalizedString(item, tableName: nil, bundle: Bundle.main, value: item.capitalized, comment: "")
			
			cell.navigationTitle.text = itemTitle
			
			if let icon = icons[item]
			{
				cell.navigationIcon.image = UIImage(named: icon)
			}
		}
		else if indexPath.section == 1
		{
			if let appDelegate = UIApplication.shared.delegate as? ArtcodeAppDelegate
			{
				if indexPath.item >= appDelegate.server.accounts.count
				{
					cell.navigationTitle.text = "Login"
					cell.navigationIcon.image = UIImage(named: "ic_lock_18pt")
				}
				else
				{
					let accounts =  appDelegate.server.accounts.keys.sorted()
					if let account = appDelegate.server.accounts[accounts[indexPath.item]]
					{
						if account.local
						{
							cell.navigationIcon.image = UIImage(named: "ic_folder_18pt")
						}
						else
						{
							cell.navigationIcon.image = UIImage(named: "ic_cloud_18pt")
						}
						
						cell.navigationTitle.text = account.name
					}
				}
			}
		}
		else if indexPath.section == 2
		{
			let item = about[indexPath.item]
			let itemTitle = NSLocalizedString(item, tableName: nil, bundle: Bundle.main, value: item.capitalized, comment: "")
			
			cell.navigationTitle.text = itemTitle
			cell.navigationIcon.image = UIImage(named: "ic_help_18pt")
		}
		return cell;
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		if indexPath.section == 0
		{
			let item = navigation[indexPath.item]
			if item == "recommended"
			{
				drawerController.centerViewController = RecommendedViewController()
				drawerController.closeDrawer(animated: true, completion: nil)
			}
			else if item == "recent"
			{
				drawerController.centerViewController = RecentViewController()
				drawerController.closeDrawer(animated: true, completion: nil)
			}
			else if item == "starred"
			{
				drawerController.centerViewController = StarredViewController()
				drawerController.closeDrawer(animated: true, completion: nil)
			}
			
			let itemTitle = NSLocalizedString(item, tableName: nil, bundle: Bundle.main, value: item.capitalized, comment: "")
			
			drawerController.title = itemTitle
		}
		else if indexPath.section == 1
		{
			if let appDelegate = UIApplication.shared.delegate as? ArtcodeAppDelegate
			{
				if indexPath.item < appDelegate.server.accounts.count
				{
					// Create library view controller
					let accounts =  appDelegate.server.accounts.keys.sorted()
					if let account = appDelegate.server.accounts[accounts[indexPath.item]]
					{
						drawerController.title = account.name
						drawerController.centerViewController = AccountViewController(account: account)
						drawerController.closeDrawer(animated: true, completion: nil)
					}
				}
				else if indexPath.item >= appDelegate.server.accounts.count
				{
					GIDSignIn.sharedInstance().uiDelegate = self
					GIDSignIn.sharedInstance().signIn()
					// Add account
				}
			}
		}
		else if indexPath.section == 2
		{
			if indexPath.item == 0
			{
				navigationController?.pushViewController(AboutArtcodesViewController(), animated: true)
			}
			
			let item = about[indexPath.item]
			let itemTitle = NSLocalizedString(item, tableName: nil, bundle: Bundle.main, value: item.capitalized, comment: "")
			
			drawerController.title = itemTitle
		}
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
	{
		if section == 1
		{
			return NSLocalizedString("libraries", tableName: nil, bundle: Bundle.main, value: "My Experiences", comment: "")
		}
		else if section == 2
		{
			return NSLocalizedString("about", tableName: nil, bundle: Bundle.main, value: "About", comment: "")
		}
		
		return nil
	}
	
	func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!)
	{
		print("Signin Present")
		present(viewController, animated: true, completion: nil)
	}
	
	func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!)
	{
		print("Signin Dismiss")
		viewController.dismiss(animated: true, completion: nil)
	}
	
	func numberOfSections(in tableView: UITableView) -> Int
	{
		return 3
	}
}
