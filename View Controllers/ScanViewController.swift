//
//  ACScanViewController.swift
//  aestheticodes
//
//  Created by Kevin Glover on 09/06/2014.
//  Copyright (c) 2014 horizon. All rights reserved.
//

import Foundation
import UIKit

class ScanViewController : UIViewController, MarkerFoundDelegate
{
	@IBOutlet var imageView: UIImageView
	@IBOutlet var progressView: UIProgressView

	@IBOutlet var topFrame: UIView
	@IBOutlet var bottomFrame: UIView

	
	var camera = ACCamera()
	var temporalMarkers = TemporalMarkers()
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		markerSettings.load()
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
		NSLog("View will disappear")
		super.viewWillDisappear(animated)

		navigationController.navigationBarHidden = false
		
		camera.stop()
		NSLog("View will disappear 2")
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject)
	{
		super.prepareForSegue(segue, sender: sender)
		
		if segue.identifier? == "MarkerDetailSegue"
		{
			NSLog("Marker Detail Segue")
			let vc = segue.destinationViewController as MarkerDetailViewController
			if sender is MarkerDetail
			{
				vc.marker = sender as MarkerDetail
			}
			NSLog("Marker Detail Segue 2")
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
					performSegueWithIdentifier("MarkerDetailSegue", sender: markerDetail!)
				}
				else
				{
					UIApplication.sharedApplication().openURL(NSURL(string: markerDetail!.action))
				}
			}
		}
	}
}
