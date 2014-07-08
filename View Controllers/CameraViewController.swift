//
//  ACScanViewController.swift
//  aestheticodes
//
//  Created by Kevin Glover on 09/06/2014.
//  Copyright (c) 2014 horizon. All rights reserved.
//

import Foundation
import UIKit

class CameraViewController : UIViewController, MarkerFoundDelegate, UICollectionViewDataSource
{
	@IBOutlet var imageView: UIImageView
	@IBOutlet var progressView: UIProgressView
	
	@IBOutlet var modeSelection: UICollectionView
	
	@IBOutlet var topFrame: UIView
	@IBOutlet var bottomFrame: UIView
	
	var camera = ACCamera()
	var temporalMarkers = TemporalMarkers()
	let queue = NSOperationQueue()
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		loadSettings()
		modeSelection.dataSource = self
	}
	
	func collectionView(collectionView: UICollectionView!, numberOfItemsInSection section: Int) -> Int
	{
		return markerSettings.viewModes.count
	}
	
	func collectionView(collectionView: UICollectionView!, cellForItemAtIndexPath indexPath: NSIndexPath!) -> UICollectionViewCell!
	{
		var cell = collectionView.dequeueReusableCellWithReuseIdentifier("modeView", forIndexPath: indexPath) as UICollectionViewCell
		for view : AnyObject in cell.contentView.subviews
		{
			if view is UILabel
			{
				(view as UILabel).text = markerSettings.viewModes[indexPath.row]
			}
		}
		return cell
	}
	
	override func viewWillAppear(animated: Bool)
	{
		super.viewWillAppear(animated)
		
		navigationController.navigationBarHidden = true
	}
	
	override func viewDidAppear(animated: Bool)
	{
		super.viewDidAppear(animated)

		camera.settings = markerSettings
		camera.markerDelegate = self
		camera.start(imageView)
	}
	
	override func viewWillDisappear(animated: Bool)
	{
		super.viewWillDisappear(animated)

		navigationController.navigationBarHidden = false
		
		camera.stop()
	}
	
	func loadSettings()
	{
		// Load in local settings file while loading url
		let path = NSBundle.mainBundle().pathForResource("settings", ofType: "json")
		if path
		{
			let json = JSONValue(NSData(contentsOfFile: path))
			markerSettings.load(json)
		}
		
		let url = NSURL(string:markerSettings.updateURL)
		let request = NSURLRequest(URL:url)
		let config = NSURLSessionConfiguration.defaultSessionConfiguration()
		let session = NSURLSession(configuration: config)
		session.dataTaskWithRequest(request, completionHandler: {(data: NSData!, response: NSURLResponse!, error: NSError!) in
			NSLog("\(response)")
			if(!data)
			{
				return
			}
			NSLog("\(error)")
			let json = JSONValue(data)
			markerSettings.load(json)			
			}).resume()
	}
	
	func updateModes()
	{
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject)
	{
		super.prepareForSegue(segue, sender: sender)
		
		if segue.identifier? == "MarkerDetailSegue"
		{
			let vc = segue.destinationViewController as MarkerDetailViewController
			if sender is MarkerDetail
			{
				vc.marker = sender as MarkerDetail
			}
		}
	}
	
	@IBAction func segmentChange(sender: UISegmentedControl)
	{
		camera.drawMode = sender.selectedSegmentIndex;
	}
	
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		NSLog("Received memory warning")
		camera.stop()
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle
	{
		return UIStatusBarStyle.LightContent
	}
	
	func markersFound(markers: NSDictionary)
	{
		dispatch_async(dispatch_get_main_queue(),
		{
			if self.temporalMarkers.hasIntegrationStarted()
			{
				self.progressView.progress = 0
				self.progressView.hidden = false
			}
			
			var percent = self.temporalMarkers.integration
			if (percent == 1.0)
			{
				self.progressView.hidden = true;
			}
			self.progressView.setProgress(percent, animated: true)
		});
		
		temporalMarkers.integrateMarkers(markers)
		
		if temporalMarkers.isMarkerDetectionTimeUp()
		{
			let marker = temporalMarkers.guessMarker!
			temporalMarkers.reset()
			camera.stop();
			progressView.hidden = true;
			let markerDetail = markerSettings.markers[marker.codeKey]
			if(markerDetail)
			{

				NSLog("Found marker \(marker.codeKey) with URL \(markerDetail!.action)")
				if(markerDetail!.showDetail)
				{
					NSLog("Performing segue")
					dispatch_async(dispatch_get_main_queue(),
					{
						self.performSegueWithIdentifier("MarkerDetailSegue", sender: markerDetail!)
					});
				}
				else
				{
					UIApplication.sharedApplication().openURL(NSURL(string: markerDetail!.action))
				}
			}
		}
	}
}
