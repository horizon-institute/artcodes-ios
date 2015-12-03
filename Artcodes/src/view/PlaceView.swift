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

class PlaceView: UIView
{
	@IBOutlet weak var navigationTitle: UILabel!
	var availability: Availability?
	{
		didSet
		{
			navigationTitle.text = availability?.name
		}
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
	}

	@IBAction func openPlace(sender: AnyObject)
	{
		var url: NSURL?
		if (UIApplication.sharedApplication().canOpenURL(NSURL(string:"comgooglemaps://")!))
		{
			url = NSURL(string:
				"comgooglemaps://?center=\(availability!.lat!),\(availability!.lon!)&zoom=14")
		}
		else
		{
			url = NSURL(string:"http://maps.apple.com/?ll=\(availability!.lat!),\(availability!.lon!)")
		}
		
		if url != nil
		{
			UIApplication.sharedApplication().openURL(url!)
		}
	}
}
