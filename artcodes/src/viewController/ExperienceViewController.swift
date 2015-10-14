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
import artcodesScanner
import Alamofire
import AlamofireImage

class ExperienceViewController: GAITrackedViewController, UITabBarDelegate
{
	@IBOutlet weak var experienceImage: UIImageView!
	@IBOutlet weak var experienceIcon: UIImageView!
	@IBOutlet weak var experienceTitle: UILabel!
	@IBOutlet weak var experienceDescription: UILabel!
	@IBOutlet weak var buttonBar: UITabBar!
	@IBOutlet weak var starButton: UITabBarItem!
	@IBOutlet weak var imageProgress: UIActivityIndicatorView!

	var experience: Experience!
	
	init(experience: Experience)
	{
		super.init(nibName:"ExperienceViewController", bundle:nil)
		self.experience = experience
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
	}
	
    override func viewDidLoad()
	{
        super.viewDidLoad()
		
        screenName = "View Experience"
    }
	
	override func viewWillAppear(animated: Bool)
	{
		super.viewWillAppear(animated)
		buttonBar.backgroundImage = UIImage()
		buttonBar.shadowImage = UIImage()
		
		buttonBar.tintColor = UIColor.blackColor()
		
		for barItem in buttonBar.items!
		{
			if let image = barItem.image
			{
				barItem.image = image.imageWithRenderingMode(.AlwaysOriginal)
			}
			barItem.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.blackColor()], forState: .Normal)
		}
		
		// Do any additional setup after loading the view.
		experienceTitle.text = experience.name
		experienceDescription.text = experience.description
		experienceImage.loadURL(experience.image, aspect: true, progress: imageProgress)
		experienceIcon.loadURL(experience.icon)
		
		updateStar()
	}

	func updateStar()
	{
		if let appDelegate = UIApplication.sharedApplication().delegate as? ArtcodeAppDelegate
		{
			if let id = experience.id
			{
				if appDelegate.server.starred.contains(id)
				{
					starButton.title = "Unstar"
					starButton.image = UIImage(named: "ic_star_18pt")?.imageWithRenderingMode(.AlwaysOriginal)
				}
				else
				{
					starButton.title = "Star"
					starButton.image = UIImage(named: "ic_star_border_18pt")?.imageWithRenderingMode(.AlwaysOriginal)
				}
				starButton.selectedImage = starButton.image
			}
		}
	}
	
	func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem)
	{
		if item.tag == 1
		{
			navigationController?.pushViewController(ExperienceEditViewController(experience: experience), animated: true)
		}
		else if item.tag == 3
		{
			if let appDelegate = UIApplication.sharedApplication().delegate as? ArtcodeAppDelegate
			{
				if let id = experience.id
				{
					var starred =  appDelegate.server.starred
					if starred.contains(id)
					{
						starred.removeObject(id)
						appDelegate.server.starred = starred
						updateStar()
					}
					else
					{
						starred.append(id)
						appDelegate.server.starred = starred
						updateStar()
					}
				}
			}
		}
		else if item.tag == 4
		{
			if let id = experience.id
			{
				if let experienceURL = NSURL(string: id)
				{
					presentViewController(UIActivityViewController(activityItems: [experience.name!, experienceURL], applicationActivities: nil), animated: true, completion: nil)
				}
			}
		}
	}
	
    override func didReceiveMemoryWarning()
	{
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
