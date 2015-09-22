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
import artcodesScanner
import Alamofire
import AlamofireImage

class ExperienceViewCell: UITableViewCell
{
	var request: Request?
	var experience: Experience?
	{
		didSet
		{
			experienceName.text = experience?.name
            experienceIcon.image = nil
            if let iconURL = experience?.icon
			{
				if let url = NSURL(string: iconURL)
				{
					experienceIcon.af_setImageWithURL(url)
				}
			}
		}
	}
	
	@IBOutlet weak var experienceIcon: UIImageView!
	@IBOutlet weak var experienceName: UILabel!
	
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
		selectionStyle = .None
        
        let tapper = UITapGestureRecognizer(target: self, action: "openExperience")
        tapper.numberOfTapsRequired = 1
        tapper.numberOfTouchesRequired = 1
        gestureRecognizers = [tapper]
	}
    
	@IBAction func scanExperience(sender: AnyObject)
	{
        if let appDelegate = UIApplication.sharedApplication().delegate as? ArtcodeAppDelegate
		{
            let vc = ScannerViewController()
            vc.experience = experience
            appDelegate.navigationController.pushViewController(vc, animated: true)
		}
	}
    
    func openExperience()
    {

        if let appDelegate = UIApplication.sharedApplication().delegate as? ArtcodeAppDelegate
        {
            let vc = ExperienceViewController()
            vc.experience = experience!
            vc.server = appDelegate.server
            appDelegate.navigationController.pushViewController(vc, animated: true)
        }
    }
	
	override init(style: UITableViewCellStyle, reuseIdentifier: String!)
	{
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		selectionStyle = .None
	}
}
