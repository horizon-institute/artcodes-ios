//
//  ACScanViewController.swift
//  aestheticodes
//
//  Created by Kevin Glover on 09/06/2014.
//  Copyright (c) 2014 horizon. All rights reserved.
//

import Foundation
import UIKit

class ACScanViewController : UIViewController
{
	@IBOutlet var imageView: UIImageView
	@IBOutlet var progressView: UIProgressView
	var camera: ACCamera?
	var drawMode: Int = 0
	var temporalMarkers = TemporalMarkers()
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		drawMode = 0;
		
		// Do any additional setup after loading the view, typically from a nib.
		camera = ACCamera(imageView)
		temporalMarkers = TemporalMarkers()
	}
	
	override func viewDidAppear(animated: Bool)
	{
		super.viewDidAppear(animated)
		
		wakeCamera()
	
		//NSNotificationCenter.defaultCenter().addObserver(self, selector: , name: UIApplicationDidBecomeActiveNotification, object: nil)
	}
	
	override func viewWillDisappear(animated: Bool)
	{
		super.viewWillDisappear(animated)
		
		NSNotificationCenter.defaultCenter().removeObserver(self, name:UIApplicationDidBecomeActiveNotification, object: nil)
		
		if(camera.isRunning())
		{
			camera.stop()
		}
	}
	
	func wakeCamera()
	{
		if (camera.isRunning())
		{
			camera.stop()
		}
		camera.start()
	}
	
	@IBAction func segmentChange(sender: AnyObject)
	{
		var segmentedControl = sender as UISegmentedControl;
		camera.drawMode = segmentedControl.selectedSegmentIndex;
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
}
