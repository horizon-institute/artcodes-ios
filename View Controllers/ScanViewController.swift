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
	var camera = ACCamera()
	var temporalMarkers = TemporalMarkers()
	var settings = MarkerSettings(file: "settings")
	
	override func viewDidAppear(animated: Bool)
	{
		super.viewDidAppear(animated)

		camera.markerDelegate = self
		camera.start(imageView)
	
		//NSNotificationCenter.defaultCenter().addObserver(self, selector: , name: UIApplicationDidBecomeActiveNotification, object: nil)
	}
	
	override func viewWillDisappear(animated: Bool)
	{
		super.viewWillDisappear(animated)
		
		NSNotificationCenter.defaultCenter().removeObserver(self, name:UIApplicationDidBecomeActiveNotification, object: nil)
		
		camera.stop()
	}
	
	@IBAction func segmentChange(sender: UISegmentedControl)
	{
		camera.drawMode = sender.selectedSegmentIndex;
	}
	
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
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
			let markerUrl = settings.markers[marker.codeKey]
			UIApplication.sharedApplication().openURL(NSURL(string: markerUrl))
		}
	}
}
