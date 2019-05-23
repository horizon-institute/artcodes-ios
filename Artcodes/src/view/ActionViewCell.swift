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

class ActionViewCell: UITableViewCell
{
	@objc var action: Action?
	{
		didSet
		{
			actionName.text = action?.name
			actionURL.text = action?.displayURL
			
			if (action == nil || action?.codes.count == 0)
			{
				actionDetail.text = ""
			}
			else if (action?.codes.count == 1)
			{
				actionDetail.text = action?.codes[0]
			}
			else if (action?.match == Match.all)
			{
				actionDetail.text = "Group"
			}
			else if (action?.match == Match.sequence)
			{
				actionDetail.text = "Sequence"
			}
			else
			{
				actionDetail.text = "\(action!.codes.count) codes"
			}
		}
	}
	
	@IBOutlet weak var actionName: UILabel!
	@IBOutlet weak var actionURL: UILabel!
	@IBOutlet weak var actionDetail: UILabel!
	
	
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
	}
	
	override func layoutSubviews()
	{
		super.layoutSubviews()
	}
}
