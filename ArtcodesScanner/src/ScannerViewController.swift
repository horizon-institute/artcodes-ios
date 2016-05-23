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
	
	var labelTimer = NSTimer()
	let captureSession = AVCaptureSession()
	var captureDevice : AVCaptureDevice?
	var deviceInput: AVCaptureDeviceInput?
	var facing = AVCaptureDevicePosition.Back
	let frameQueue = dispatch_queue_create("Frame Processing Queue", DISPATCH_QUEUE_SERIAL)
	
	public var experience: Experience!
	let frameProcessor = FrameProcessor()
	
	private var progressWidth: CGFloat = 0
	@IBOutlet weak var scanViewOffset: NSLayoutConstraint!
	
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
		self.scanViewOffset.constant = self.progressWidth
	
		UIView.animateWithDuration(0.4, delay:0.4, options: [.CurveLinear], animations: {
			
			self.view.layoutIfNeeded()
			
			}, completion: { animationFinished in
				self.configureAnimation()
		})
	}
	
	public func markersDetected(markers: [AnyObject])
	{
	}
	
	@IBAction func backButtonPressed(sender: AnyObject)
	{
		if let nav = navigationController
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
					
						if captureDevice.isFocusModeSupported(AVCaptureFocusMode.ContinuousAutoFocus)
						{
							captureDevice.focusMode = .ContinuousAutoFocus
						}
						if captureDevice.isExposureModeSupported(AVCaptureExposureMode.ContinuousAutoExposure)
						{
							captureDevice.exposureMode = .ContinuousAutoExposure
						}
						if captureDevice.isWhiteBalanceModeSupported(AVCaptureWhiteBalanceMode.ContinuousAutoWhiteBalance)
						{
							captureDevice.whiteBalanceMode = .ContinuousAutoWhiteBalance
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
						
						let videoOutput = AVCaptureVideoDataOutput()
						videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
						videoOutput.alwaysDiscardsLateVideoFrames = true
						let settings = DetectionSettings(experience: experience)
						settings.handler = { markers in
							self.markersDetected(markers)
						}
						frameProcessor.overlay = overlayImage.layer
						frameProcessor.createPipeline(experience.pipeline, andSettings: settings)
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
			sender.setImage(UIImage(named: "ic_camera_back", inBundle: NSBundle(identifier: "uk.ac.horizon.ArtcodesScanner"), compatibleWithTraitCollection: nil), forState: .Normal)
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
	
	func delay(delay:Double, closure:()->()) {
		dispatch_after(
			dispatch_time(
				DISPATCH_TIME_NOW,
				Int64(delay * Double(NSEC_PER_SEC))
			),
			dispatch_get_main_queue(), closure)
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
	
	public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask
	{
		NSLog("Supported interface scanner")
		return [UIInterfaceOrientationMask.Portrait]
	}
	
	func makeCirclePath(origin: CGPoint, radius: CGFloat) -> CGPathRef
	{
		let size = radius * 2
		
		return UIBezierPath(roundedRect: CGRect(x: origin.x - radius, y: origin.y - radius, width: size, height: size), cornerRadius: radius).CGPath
	}
	
	@IBAction func showMenu(sender: AnyObject)
	{
		// TODO updateMenu()
	
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
		captureSession.stopRunning()
		let value = UIInterfaceOrientation.Unknown.rawValue;
		UIDevice.currentDevice().setValue(value, forKey: "orientation")
		navigationController?.navigationBarHidden = false
	}
}
