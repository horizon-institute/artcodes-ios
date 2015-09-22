//
//  ExperienceItemView.swift
//  artcodes
//
//  Created by Kevin Glover on 04/08/2015.
//  Copyright (c) 2015 Horizon. All rights reserved.
//

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
