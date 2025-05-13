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
import UIKit

class AccountViewController: ExperienceCollectionViewController
{
    let account: Account
    
    init(account: Account)
    {
        self.account = account
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        self.account = LocalAccount()
        super.init(coder: aDecoder)
    }
	
    override func viewDidLoad()
	{
		super.viewDidLoad()
		
        sideMenuController?.title = "Library"
		
        sorted = true
		errorIcon.image = UIImage(named: "ic_folder_144pt")
        errorDetails.isHidden = false
		
		if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
		{
			layout.footerReferenceSize = CGSize(width: 100, height: 88)
		}
	}
	
    override func viewDidAppear(_ animated: Bool)
	{
		progress += 1
		account.loadLibrary { (experiences) -> Void in
			self.progress -= 1
            self.setExperienceURIs(experienceURIs: experiences)
            self.fab.addTarget(self, action: #selector(AccountViewController.addExperience), for: .touchUpInside)
            self.fab.isHidden = false
		}
	}
	
    @objc func addExperience()
	{
        if let appDelegate = UIApplication.shared.delegate as? ArtcodeAppDelegate
		{
			appDelegate.navigation.pushViewController(ExperienceNewViewController(account: account), animated: true)
		}
	}
}
