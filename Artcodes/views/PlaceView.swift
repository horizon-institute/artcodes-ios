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
	@IBOutlet weak var address: UILabel!
	var availability: Availability?
	{
		didSet
		{
            navigationTitle.text = availability?.location?.name
            address.text = availability?.location?.address
		}
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
	}

	@IBAction func openPlace(_ sender: Any)
	{
        if let coordinates = availability?.location?.coordinates {
            var url: URL?
            if (UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!))
            {
                url = URL(string:"comgooglemaps://?center=\(coordinates[0]),\(coordinates[1])&zoom=14")
            }
            else
            {
                url = URL(string:"http://maps.apple.com/?ll=\(coordinates[0]),\(coordinates[1])")
            }
            
            if let openUrl = url
            {
                UIApplication.shared.open(openUrl)
            }
        }
	}
}
