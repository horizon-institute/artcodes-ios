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
import UIKit
import GoogleSignIn
import SideMenu

class MenuViewController: UITableViewController
{
    let cellName = "MenuItem"
    
    var navigation = ["recommended"]
    let about = ["artcodes"]
    let icons = ["recommended": "ic_photo_camera_18pt", "recent": "ic_history_18pt", "starred": "ic_star_18pt"]
            
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 48.0
        tableView.separatorColor = .white
        
        tableView.register(UINib(nibName: cellName, bundle:nil), forCellReuseIdentifier: cellName)
        tableView.selectRow(at: NSIndexPath(item: 0, section: 0) as IndexPath, animated: false, scrollPosition: UITableView.ScrollPosition.top)
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
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell :MenuItem = tableView.dequeueReusableCell(withIdentifier: cellName) as! MenuItem
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
                    let accounts = appDelegate.server.accounts.keys.sorted()
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if indexPath.section == 0
        {
            let item = navigation[indexPath.item]
            if item == "recommended"
            {
                sideMenuController?.setContentViewController(to: RecommendedViewController(), animated: true)
                sideMenuController?.hideMenu()
            }
            else if item == "recent"
            {
                sideMenuController?.setContentViewController(to: RecentViewController(), animated: true)
                sideMenuController?.hideMenu()
            }
            else if item == "starred"
            {
                sideMenuController?.setContentViewController(to: StarredViewController(), animated: true)
                sideMenuController?.hideMenu()
            }
            
            let itemTitle = NSLocalizedString(item, tableName: nil, bundle: Bundle.main, value: item.capitalized, comment: "")
            
            // TODO drawer.title = itemTitle
        }
        else if indexPath.section == 1
        {
            if let appDelegate = UIApplication.shared.delegate as? ArtcodeAppDelegate
            {
                if indexPath.item < appDelegate.server.accounts.count
                {
                    // Create library view controller
                    let accounts = appDelegate.server.accounts.keys.sorted()
                    if let account = appDelegate.server.accounts[accounts[indexPath.item]]
                    {
                        // TODO drawer.title = account.name
                        sideMenuController?.setContentViewController(to: AccountViewController(account: account), animated: true)
                        sideMenuController?.hideMenu()
                    }
                }
                else if indexPath.item >= appDelegate.server.accounts.count
                {
                    GIDSignIn.sharedInstance.signIn(withPresenting: self) { signInResult, error in
                        guard error == nil else {
                            // Handle error
                            print("Error signing in: \(error!.localizedDescription)")
                            return
                        }

                        guard let user = signInResult?.user else {
                            // Handle case where user is nil
                            print("User is nil")
                            return
                        }
                        
                        if let profile = user.profile
                        {
                            print(user.profile)
                            tableView.reloadData()
                            let account = appDelegate.server.addAccount(name: profile.name, email: profile.email, token: user.accessToken.tokenString)
                            self.sideMenuController?.setContentViewController(to: AccountViewController(account: account), animated: true)
                            self.sideMenuController?.hideMenu()
                        }
                    }
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
            
            // TODO drawer.title = itemTitle
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
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
    
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 3
    }
}
