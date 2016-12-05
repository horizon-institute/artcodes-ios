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

import AVFoundation
import UIKit
import SwiftyJSON

public class ScannerViewController: UIViewController
{
	@IBOutlet weak var cameraView: UIView!
	@IBOutlet weak var overlayImage: UIImageView!

	@IBOutlet weak var backButton: UIButton!
	@IBOutlet weak var menu: UIView!
	@IBOutlet weak var menuButton: UIButton!
	@IBOutlet weak var menuLabel: UILabel!
	@IBOutlet weak var menuLabelHeight: NSLayoutConstraint!

	@IBOutlet weak var viewfinderBottom: UIView!
	@IBOutlet public weak var actionButton: UIButton!
	
	@IBOutlet public weak var thumbnailView: UIView!
	@IBOutlet weak var focusLabel: UILabel!
	
	var shouldRemoveAutofocusObserverOnExit = false
	
	public var markerDetectionHandler: MarkerDetectionHandler?
	
	var labelTimer = NSTimer()
	let captureSession = AVCaptureSession()
	var captureDevice : AVCaptureDevice?
	var deviceInput: AVCaptureDeviceInput?
	var facing = AVCaptureDevicePosition.Back
	let frameQueue = dispatch_queue_create("Frame Processing Queue", DISPATCH_QUEUE_SERIAL)
	
	var returnClosure: ((String)->())?
	
	public var experience: Experience!
	let frameProcessor = FrameProcessor()
	
	private var progressWidth: CGFloat = 0
	@IBOutlet weak var scanViewOffset: NSLayoutConstraint!
	
	public class func scanner(dict: NSDictionary, closure:(String)->()) -> ScannerViewController?
	{
		let experience = Experience(json: JSON(dict))
		let scanner = ScannerViewController(experience: experience)
		scanner.returnClosure = closure;
		scanner.markerDetectionHandler = MarkerCodeDetectionHandler(experience: experience, closure: closure)
		return scanner
	}
	
	public init(experience: Experience)
	{
		super.init(nibName:"ScannerViewController", bundle:NSBundle(identifier: "uk.ac.horizon.ArtcodesScanner"))
		self.experience = experience
	}

	public required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
	}
	
	public override func viewDidLoad()
	{
		super.viewDidLoad()
		if let name = experience.name
		{
			backButton.setTitle(name, forState: .Normal)
		}
		
		progressWidth = UIScreen.mainScreen().bounds.width
	}
	
	public override func viewDidAppear(animated: Bool)
	{
		setupCamera()
	}
	
	private func configureAnimation()
	{
		scanViewOffset.constant = -1
		
		view.layoutIfNeeded()
		scanViewOffset.constant = progressWidth
	
		UIView.animateWithDuration(0.4, delay:0.4, options: [.CurveLinear], animations: {
			
			self.view.layoutIfNeeded()
			
			}, completion: { animationFinished in
				self.configureAnimation()
		})
	}
	
	@IBAction func backButtonPressed(sender: AnyObject)
	{
		if let nonNilClosure = returnClosure
		{
			// if used as library, notify caller that back was pressed
			nonNilClosure("BACK")
		}
		else if let nav = navigationController
		{
			nav.popViewControllerAnimated(true)
		}
		else
		{
			presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
		}
	}

	public override func viewWillAppear(animated: Bool)
	{
		let value = UIInterfaceOrientation.Portrait.rawValue
		UIDevice.currentDevice().setValue(value, forKey: "orientation")
		navigationController?.navigationBarHidden = true
	}

	func thumbnailViewGesture(gestureRecognizer: UIGestureRecognizer)
	{
		// translate from screen to camera coordinates
		let screenFrame: CGRect = UIScreen.mainScreen().bounds;
		let viewFrame: CGRect = self.thumbnailView.frame;
		let touchPoint: CGPoint = gestureRecognizer.locationInView(self.thumbnailView)
		let focusPoint: CGPoint = CGPointMake((viewFrame.origin.y+touchPoint.y)/screenFrame.height, (viewFrame.width-touchPoint.x)/screenFrame.width)
		
		for inputObject in captureSession.inputs
		{
			if let aVCaptureDeviceInput = inputObject as? AVCaptureDeviceInput
			{
				
				if let device = aVCaptureDeviceInput.device
				{
					do
					{
						try device.lockForConfiguration()
						if device.focusPointOfInterestSupported {
							device.focusPointOfInterest = focusPoint
						}
						if device.isFocusModeSupported(.AutoFocus)
						{
							device.focusMode = AVCaptureFocusMode.AutoFocus
						}
						if device.exposurePointOfInterestSupported {
							device.exposurePointOfInterest = focusPoint
							device.exposureMode = AVCaptureExposureMode.AutoExpose
						}
						device.unlockForConfiguration()
					}
					catch let error as NSError
					{
						NSLog("error: \(error.localizedDescription)")
					}
				}
			}
		}
	}

	
	func setupCamera()
	{
		// TODO Preset?
		captureSession.stopRunning()
		captureSession.sessionPreset = AVCaptureSessionPreset1280x720
		if let input = deviceInput
		{
			captureSession.removeInput(input)
		}
		
		for device in AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
		{
			if let captureDevice = device as? AVCaptureDevice
			{
				if(captureDevice.position == facing)
				{
					do
					{
						try captureDevice.lockForConfiguration()
						
						var focusHasBeenSet = false
						if let requestedAutoFocusMode = experience.requestedAutoFocusMode
						{
							if (requestedAutoFocusMode == "tapToFocus" && captureDevice.isFocusModeSupported(AVCaptureFocusMode.AutoFocus))
							{
								captureDevice.focusMode = .AutoFocus
								// setup a listener for when the user taps the screen
								let gestureRecognizer: UIGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(thumbnailViewGesture));
								self.thumbnailView.addGestureRecognizer(gestureRecognizer);
								
								// tell frameProcessor when camera is focusing so it can skip those frames
								captureDevice.addObserver(frameProcessor, forKeyPath:"adjustingFocus", options: NSKeyValueObservingOptions.New, context: nil)
								shouldRemoveAutofocusObserverOnExit = true
								focusHasBeenSet = true
								focusLabel.hidden = false
							}
						}
					
						if (!focusHasBeenSet && captureDevice.isFocusModeSupported(AVCaptureFocusMode.ContinuousAutoFocus))
						{
							captureDevice.focusMode = .ContinuousAutoFocus
							focusHasBeenSet = true
						}
						
						if captureDevice.isExposureModeSupported(AVCaptureExposureMode.ContinuousAutoExposure)
						{
							captureDevice.exposureMode = .ContinuousAutoExposure
						}
						if captureDevice.isWhiteBalanceModeSupported(AVCaptureWhiteBalanceMode.ContinuousAutoWhiteBalance)
						{
							captureDevice.whiteBalanceMode = .ContinuousAutoWhiteBalance
						}
						
						if let useTorch = NSUserDefaults.standardUserDefaults().objectForKey("torch_on_at_start") as? Bool
						{
							if useTorch
							{
								if captureDevice.torchAvailable
								{
									do {
										try captureDevice.setTorchModeOnWithLevel(1)
									}
									catch let error as NSError
									{
										NSLog("error: \(error.localizedDescription)")
									}
								}
							}
						}
						captureDevice.unlockForConfiguration()

						deviceInput = try AVCaptureDeviceInput(device: captureDevice)
						
						if captureSession.canAddInput(deviceInput)
						{
							captureSession.addInput(deviceInput)
						}
						
						let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
						previewLayer.frame = view.bounds
						previewLayer.videoGravity = AVLayerVideoGravityResizeAspect
						//cameraView.layer.sublayers.removeAll(keepCapacity: true)
						cameraView.layer.addSublayer(previewLayer)
						
						let settings = DetectionSettings(experience: experience, handler: getMarkerDetectionHandler())
						frameProcessor.overlay = overlayImage.layer
						frameProcessor.createPipeline(experience.pipeline, andSettings: settings)
						
						
						let videoOutput = AVCaptureVideoDataOutput()
						// Ask for the camera data in the format the first pipeline item uses.
						// In the future it might be faster to ask for YCbCr data and convert only the part of the image we need to BGR using cvtColor but there is no documentation on the data arrangement in the CbCr plane.
						videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
						if let firstImageProcessor = frameProcessor.pipeline.first as? ImageProcessor
						{
							if firstImageProcessor.requiresBgraInput()
							{
								videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: Int(kCVPixelFormatType_32BGRA)]
							}
						}
						videoOutput.alwaysDiscardsLateVideoFrames = true
						videoOutput.setSampleBufferDelegate(frameProcessor, queue: frameQueue)
							
						if captureSession.canAddOutput(videoOutput)
						{
							captureSession.addOutput(videoOutput)
						}
							
						captureSession.startRunning()
						configureAnimation()
						return
					}
					catch let error as NSError
					{
						NSLog("error: \(error.localizedDescription)")
					}
				}
			}
		}
	}
	
	@IBAction public func openAction(sender: AnyObject) {
	}
	
	public override func preferredStatusBarStyle() -> UIStatusBarStyle
	{
		return .LightContent
	}
	
	@IBAction func toggleFacing(sender: UIButton)
	{
		if facing == AVCaptureDevicePosition.Back
		{
			facing = AVCaptureDevicePosition.Front
			displayMenuText("Using front camera")
			sender.setImage(UIImage(named: "ic_camera_front", inBundle: NSBundle(identifier: "uk.ac.horizon.ArtcodesScanner"), compatibleWithTraitCollection: nil), forState: .Normal)
		}
		else
		{
			facing = AVCaptureDevicePosition.Back
			displayMenuText("Using back camera")
			sender.setImage(UIImage(named: "ic_camera_rear", inBundle: NSBundle(identifier: "uk.ac.horizon.ArtcodesScanner"), compatibleWithTraitCollection: nil), forState: .Normal)
		}
		setupCamera()
	}
	
	@IBAction func toggleThreshold(sender: UIButton)
	{
		if frameProcessor.settings.displayThreshold == 0
		{
			frameProcessor.settings.displayThreshold = 1
			displayMenuText("Thresholding visible")
			sender.tintColor = UIColor.whiteColor()
		}
		else
		{
			frameProcessor.settings.displayThreshold = 0
			displayMenuText("Thresholding hidden")
			sender.tintColor = UIColor.lightGrayColor()
		}
	}
	
	@IBAction func toggleOutline(sender: UIButton)
	{
		if frameProcessor.settings.displayOutline == 0
		{
			frameProcessor.settings.displayOutline = 1
			sender.setImage(UIImage(named: "ic_border_outer", inBundle: NSBundle(identifier: "uk.ac.horizon.ArtcodesScanner"), compatibleWithTraitCollection: nil), forState: .Normal)
			sender.tintColor = UIColor.whiteColor()
			displayMenuText("Marker outlined")
		}
		else if frameProcessor.settings.displayOutline == 1
		{
			frameProcessor.settings.displayOutline = 2
			sender.setImage(UIImage(named: "ic_border_all", inBundle: NSBundle(identifier: "uk.ac.horizon.ArtcodesScanner"), compatibleWithTraitCollection: nil), forState: .Normal)
			sender.tintColor = UIColor.whiteColor()
			displayMenuText("Marker regions outlined")
		}
		else if frameProcessor.settings.displayOutline == 2
		{
			frameProcessor.settings.displayOutline = 0
			sender.setImage(UIImage(named: "ic_border_clear", inBundle: NSBundle(identifier: "uk.ac.horizon.ArtcodesScanner"), compatibleWithTraitCollection: nil), forState: .Normal)
			sender.tintColor = UIColor.lightGrayColor()
			displayMenuText("Marker outlines hidden")
		}
	}
	
	func displayMenuText(text: String)
	{
		menuLabel.text = text
		UIView.animateWithDuration(Double(0.5), animations: {
			self.menuLabelHeight.constant = 20
			self.menu.layoutIfNeeded()
		})
		
		labelTimer.invalidate()
		labelTimer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: #selector(ScannerViewController.hideMenuText), userInfo: nil, repeats: true)
	}
	
	func hideMenuText()
	{
		UIView.animateWithDuration(Double(0.5), animations: {
			self.menuLabelHeight.constant = 0
			self.menu.layoutIfNeeded()
		})
	}
	
	@IBAction func toggleCode(sender: UIButton)
	{
		if frameProcessor.settings.displayText == 0
		{
			frameProcessor.settings.displayText = 1
			sender.tintColor = UIColor.whiteColor()
			displayMenuText("Marker codes visible")
		}
		else
		{
			frameProcessor.settings.displayText = 0
			sender.tintColor = UIColor.lightGrayColor()
			displayMenuText("Marker codes hidden")
		}
	}
	@IBAction func toggleTorch(sender: UIButton)
	{
		for inputObject in captureSession.inputs
		{
			if let aVCaptureDeviceInput = inputObject as? AVCaptureDeviceInput
			{
				
				if let captureDevice = aVCaptureDeviceInput.device
				{
					if captureDevice.torchAvailable
					{
						do {
							try captureDevice.lockForConfiguration()
							if captureDevice.torchActive
							{
								captureDevice.torchMode = .Off
								sender.tintColor = UIColor.lightGrayColor()
								sender.setImage(UIImage(named: "ic_light_off", inBundle: NSBundle(identifier: "uk.ac.horizon.ArtcodesScanner"), compatibleWithTraitCollection: nil), forState: .Normal)
								displayMenuText("Torch off")
							}
							else
							{
								try captureDevice.setTorchModeOnWithLevel(1)
								sender.tintColor = UIColor.whiteColor()
								sender.setImage(UIImage(named: "ic_light_on", inBundle: NSBundle(identifier: "uk.ac.horizon.ArtcodesScanner"), compatibleWithTraitCollection: nil), forState: .Normal)
								displayMenuText("Torch on")
								
							}
							captureDevice.unlockForConfiguration()
						}
						catch let error as NSError
						{
							NSLog("error: \(error.localizedDescription)")
						}
					}
					else
					{
						displayMenuText("Torch not available")
					}
				}
			}
		}
	}
	
	public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask
	{
		return [UIInterfaceOrientationMask.Portrait]
	}
	
	func makeCirclePath(origin: CGPoint, radius: CGFloat) -> CGPathRef
	{
		let size = radius * 2
		return UIBezierPath(roundedRect: CGRect(x: origin.x - radius, y: origin.y - radius, width: size, height: size), cornerRadius: radius).CGPath
	}
	
	@IBAction func showMenu(sender: AnyObject)
	{
		let origin = CGPointMake(CGRectGetMidX(menuButton.frame) - menu.frame.origin.x, CGRectGetMidY(menuButton.frame) - menu.frame.origin.y);
		let mask = CAShapeLayer()
		mask.path = makeCirclePath(origin, radius: 0)
		mask.fillColor = UIColor.blackColor().CGColor
	
		menu.layer.mask = mask
	
		CATransaction.begin()
		let animation = CABasicAnimation(keyPath: "path")
		animation.duration = 0.25
		animation.fillMode = kCAFillModeForwards
		animation.removedOnCompletion = false
	
		let newPath = makeCirclePath(origin, radius:menu.bounds.width)
		animation.fromValue = mask.path
		animation.toValue = newPath
	
		CATransaction.setCompletionBlock() {
			self.menu.layer.mask = nil;
		}

		mask.addAnimation(animation, forKey:"path")
		CATransaction.commit()
	
		menu.hidden = false
		menuButton.hidden = true
	}
	
	@IBAction func hideMenu(sender: AnyObject)
	{
		let origin = CGPointMake(CGRectGetMidX(menuButton.frame) - menu.frame.origin.x, CGRectGetMidY(menuButton.frame) - menu.frame.origin.y);
		let mask = CAShapeLayer()
		mask.path = makeCirclePath(origin, radius:menu.bounds.width)
		mask.fillColor = UIColor.blackColor().CGColor
	
		menu.layer.mask = mask
	
		CATransaction.begin()
		let animation = CABasicAnimation(keyPath: "path")
		animation.duration = 0.25
		animation.fillMode = kCAFillModeForwards
		animation.removedOnCompletion = false
	
		let newPath = makeCirclePath(origin, radius:0)
	
		animation.fromValue = mask.path
		animation.toValue = newPath
	
		CATransaction.setCompletionBlock() {
			self.menu.hidden = true
			self.menuButton.hidden = false
			self.menu.layer.mask = nil
		}
		mask.addAnimation(animation, forKey:"path")
		CATransaction.commit()
	}
	
	public override func viewWillDisappear(animated: Bool)
	{
		NSLog("Scanner View Controller disappear")

		dispatch_async(frameQueue, {
			self.captureSession.stopRunning()
		})

		let value = UIInterfaceOrientation.Unknown.rawValue;
		UIDevice.currentDevice().setValue(value, forKey: "orientation")
		navigationController?.navigationBarHidden = false
	}
	
	public override func viewDidDisappear(animated: Bool) {
		super.viewDidDisappear(animated)
		self.markerDetectionHandler = nil
	}
	
	public func getMarkerDetectionHandler() -> MarkerDetectionHandler
	{
		if (self.markerDetectionHandler == nil)
		{
			self.markerDetectionHandler = MarkerCodeDetectionHandler(experience: self.experience)
			{ (code) in
					
			}
		}
		return self.markerDetectionHandler!
	}
}
