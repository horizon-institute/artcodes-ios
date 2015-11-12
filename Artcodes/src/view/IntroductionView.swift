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

class IntroductionView: UIView
{
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var descriptionLabel: UILabel!
	@IBOutlet weak var image: UIImageView!
	@IBOutlet weak var imageHeight: NSLayoutConstraint!
	
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
	}

	override func layoutSubviews()
	{
		super.layoutSubviews()
		
		let height = image.bounds.width * image.image!.size.height / image.image!.size.width
		imageHeight.constant = height
		
		titleLabel.preferredMaxLayoutWidth = titleLabel.bounds.width
		descriptionLabel.preferredMaxLayoutWidth = descriptionLabel.bounds.width
	}

	@IBAction func openMore(sender: AnyObject)
	{
		if let nsurl = ArtcodeAppDelegate.chromifyURL("http://aestheticodes.com/info/")
		{
			UIApplication.sharedApplication().openURL(nsurl)
		}
	}
		
	@IBAction func dismiss(sender: AnyObject)
	{
		
	}
}
