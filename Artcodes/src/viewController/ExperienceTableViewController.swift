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
import ArtcodesScanner

class ExperienceTableViewController: GAITrackedViewController, UITableViewDataSource, UITableViewDelegate
{
    var groups: [String: [String]] = [:]
   	var experiences: [String: Experience] = [:]
   	var keys: [String] = []
    var sorted = false
   	var ordering: [String]
    {
        return []
    }
    
	
	@IBOutlet weak var progressView: UIActivityIndicatorView!
	@IBOutlet weak var tableView: UITableView!
	
	init()
	{
		super.init(nibName:"ExperienceTableViewController", bundle:nil)
	}
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?)
    {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
	
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
	}
	
    func addExperienceURIs(experienceURIs: [String], forGroup: String)
    {
		if experienceURIs.isEmpty
		{
			return
		}
		
        groups[forGroup] = experienceURIs
        
        // Update keys
        keys = []
        for key in ordering
        {
            if groups.indexForKey(key) != nil
            {
                keys.append(key)
            }
        }
        
        for key in groups.keys
        {
            if !keys.contains(key)
            {
                keys.append(key)
            }
        }
        
        for experienceURI in experienceURIs
        {
            NSLog("Adding \(experienceURI) in \(forGroup)")
            if experiences.indexForKey(experienceURI) == nil
            {
				if let appDelegate = UIApplication.sharedApplication().delegate as? ArtcodeAppDelegate
				{
					appDelegate.server.loadExperience(experienceURI) { (experience) -> Void in
						if experience.id == nil
						{
							experience.id = experienceURI
						}
						NSLog("Loaded \(experienceURI): \(experience.json)")
						self.experiences[experienceURI] = experience
						self.tableView.reloadData()
					}
				}
			}
        }
    }
    
	override func viewDidLoad()
	{
		super.viewDidLoad()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 56.0
        
		let nibName = UINib(nibName: "ExperienceViewCell", bundle:nil)
		tableView.registerNib(nibName, forCellReuseIdentifier: "ExperienceViewCell")
    }
	
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if let experienceURIs = groups[keys[section]]
        {
            var count = 0
            for experienceURI in experienceURIs
            {
                if experiences.indexForKey(experienceURI) != nil
                {
                    count++
                }
            }
            return count
        }
        return 0
    }
    
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		if let experience = experienceAt(indexPath)
		{
			let cell :ExperienceViewCell = tableView.dequeueReusableCellWithIdentifier("ExperienceViewCell") as! ExperienceViewCell
			cell.experience = experience
			return cell;
		}
		
		return UITableViewCell()
	}
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        return NSLocalizedString(keys[section], tableName: nil, bundle: NSBundle.mainBundle(), value: keys[section], comment: "")
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return keys.count
    }
    
    func experienceAt(indexPath: NSIndexPath) -> Experience?
    {
        if let items = groups[keys[indexPath.section]]
        {
            var experienceList : [Experience] = []
            for item in items
            {
                if let experience = experiences[item]
                {
                    experienceList.append(experience)
                }
            }
            
            if sorted
            {
                experienceList.sortInPlace({ $0.name?.lowercaseString < $1.name?.lowercaseString })
            }
			
			if indexPath.item < experienceList.count
			{
				return experienceList[indexPath.item]
			}
        }
        return nil
    }
}