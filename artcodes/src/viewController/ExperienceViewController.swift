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

class ExperienceViewController: ArtcodeViewController, UITabBarDelegate
{
	@IBOutlet weak var experienceImage: UIImageView!
	@IBOutlet weak var experienceIcon: UIImageView!
	@IBOutlet weak var experienceTitle: UILabel!
	@IBOutlet weak var experienceDescription: UILabel!
	@IBOutlet weak var buttonBar: UITabBar!

	var experience: Experience!
	
    init()
	{
		super.init(nibName:"ExperienceViewController", bundle:nil)
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
	}
	
    override func viewDidLoad()
	{
        super.viewDidLoad()
        
        screenName = "View Experience"
		
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
		
		if let imageURL = experience.image
		{
			if let url = NSURL(string: imageURL)
			{
				experienceImage.af_setImageWithURL(url)
			}
			
		}
		if let iconURL = experience.icon
		{
			if let url = NSURL(string: iconURL)
			{
				experienceIcon.af_setImageWithURL(url)
			}
		}
    }

	func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem)
	{
		if item.tag == 1
		{
			let vc = ExperienceEditViewController()
			vc.experience = experience
			navigationController?.pushViewController(vc, animated: true)
		}
		else if item.tag == 3
		{
			// TODO Star
		}
		else if item.tag == 4
		{
			if let experienceURL = NSURL(string: experience.id)
			{
				let objectsToShare = [experience.name!, experienceURL]
				let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
				
				self.presentViewController(activityVC, animated: true, completion: nil)
			}
		}
	}
	
    override func didReceiveMemoryWarning()
	{
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
