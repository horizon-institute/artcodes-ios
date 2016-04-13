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

import UIKit
import ArtcodesScanner
import Alamofire
import AlamofireImage

class ExperienceCardCell: UICollectionViewCell
{
	var request: Request?
	var experience: Experience!
	{
		didSet
		{
			title.text = experience?.name
            image.image = nil
			if let experienceImage = experience?.image
			{
				image.loadURL(experienceImage)
			}
			else if let experienceIcon = experience?.icon
			{
				image.loadURL(experienceIcon)
			}
			else
			{
				// TODO!
			}
		}
	}
	
	@IBOutlet weak var image: UIImageView!
	@IBOutlet weak var title: UILabel!
	
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
		// selectionStyle = .None
        
        let tapper = UITapGestureRecognizer(target: self, action: "openExperience")
        tapper.numberOfTapsRequired = 1
        tapper.numberOfTouchesRequired = 1
        gestureRecognizers = [tapper]
	}
    
	@IBAction func scanExperience(sender: AnyObject)
	{
        if let appDelegate = UIApplication.sharedApplication().delegate as? ArtcodeAppDelegate
		{
			let index = appDelegate.navigationController.viewControllers.count
			appDelegate.navigationController.pushViewController(ArtcodeViewController(experience: experience), animated: true)
			// Insert experience view in front of scan view, so we go back through it
			appDelegate.navigationController.viewControllers.insert(ExperienceViewController(experience: experience), atIndex: index)
		}
	}
    
    func openExperience()
    {
        if let appDelegate = UIApplication.sharedApplication().delegate as? ArtcodeAppDelegate
        {
            appDelegate.navigationController.pushViewController(ExperienceViewController(experience: experience), animated: true)
        }
    }
}
