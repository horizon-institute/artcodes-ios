//
//  FoundMarkerViewController.swift
//  aestheticodes
//
//  Created by Kevin Glover on 11/06/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

import Foundation

class MarkerDetailViewController : UITableViewController
{
	@IBOutlet var imageView : UIImageView

	@IBOutlet var titleLabel : UILabel
	@IBOutlet var descriptionLabel : UILabel
	
	@IBOutlet var buttonCell : UITableViewCell
	
	var marker = MarkerDetail(code: "")
	var markerImage : UIImage?
	
	override func viewWillAppear(animated: Bool)
	{
		NSLog("Marker Detail view will appear")
		titleLabel.text = String.localizedStringWithFormat(marker.title, marker.code)
		if marker.description 
		{
			descriptionLabel.text = marker.description
		}
		else if marker.action
		{
			descriptionLabel.text = marker.action
		}
		
		if marker.image
		{
			NSLog("Marker Detail image setup")
			if(marker.image?.hasPrefix("http"))
			{
				let url = NSURL(string:marker.image!)
				let request = NSURLRequest(URL:url)
				let queue = NSOperationQueue()
				
				NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler:{ response, data, error in
					if (!error)
					{
						self.imageView.image = UIImage(data: data)
					}
					else
					{
						NSLog("Error loading image: \(error?.localizedDescription)")
					}
				})
				NSLog("Loading image url")
			}
			else
			{
				imageView.image = UIImage(named: marker.image!)
			}
		}
		else
		{
			imageView.image = markerImage
		}
		
		buttonCell.hidden = !marker.action
	}
	
	@IBAction func open(sender : AnyObject)
	{
		UIApplication.sharedApplication().openURL(NSURL(string: marker.action!))
	}
}