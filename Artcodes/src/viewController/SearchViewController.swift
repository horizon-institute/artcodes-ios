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
import DrawerController

class SearchViewController: ExperienceCollectionViewController
{
    override init()
    {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad()
	{
		super.viewDidLoad()
		
        screenName = "Search"

		let back = UIBarButtonItem(image: UIImage(named: "ic_arrow_back_white"), style: .Plain, target: self, action: "back")
		let searchItem = UIBarButtonItem(customView: UITextView())
		
		navigationItem.leftBarButtonItems = [back, searchItem]
	}
	
	override func viewDidAppear(animated: Bool)
	{

		//if let appDelegate = UIApplication.sharedApplication().delegate as? ArtcodeAppDelegate
		//{
		//	setExperienceURIs(appDelegate.server.starred)
		//}
		collectionView.reloadData()
	}
	
	func back()
	{
		navigationController?.popViewControllerAnimated(true)
	}
	
	override func error(experience: String, error: NSError)
	{
		NSLog("Error loading \(experience): \(error)")
	}
}