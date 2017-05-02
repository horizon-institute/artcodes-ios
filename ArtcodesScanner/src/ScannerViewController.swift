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

open class ScannerViewController: UIViewController
{
	@IBOutlet weak var cameraView: UIView!
	@IBOutlet weak var overlayImage: UIImageView!

	@IBOutlet weak var backButton: UIButton!
	@IBOutlet weak var menu: UIView!
	@IBOutlet weak var menuButton: UIButton!
	@IBOutlet weak var menuLabel: UILabel!
	@IBOutlet weak var menuLabelHeight: NSLayoutConstraint!

	@IBOutlet weak var viewfinderBottom: UIView!
	@IBOutlet open weak var actionButton: UIButton!
	@IBOutlet open weak var takePictureButton: UIButton!
	
	@IBOutlet open weak var thumbnailView: UIView!
	@IBOutlet weak var focusLabel: UILabel!
	
	var shouldRemoveAutofocusObserverOnExit = false
	
	
	@IBOutlet open weak var helpAnimation: UIImageView!
	let helpFrameNames: [String] = ["scan_help_animation_frame1","scan_help_animation_frame2","scan_help_animation_frame3","scan_help_animation_frame4","scan_help_animation_frame5","scan_help_animation_frame6","scan_help_animation_frame7"]
	
	open var markerDetectionHandler: MarkerDetectionHandler?
	
	var labelTimer: Timer? = Timer()
	let captureSession = AVCaptureSession()
	var captureDevice : AVCaptureDevice?
	var deviceInput: AVCaptureDeviceInput?
	var facing = AVCaptureDevicePosition.back
	var frameQueue: DispatchQueue? = DispatchQueue(label: "Frame Processing Queue", attributes: [])
	
	var returnClosure: ((String)->())?
	
	open var experience: Experience!
	open var frameProcessor: FrameProcessor? = FrameProcessor()
	
	fileprivate var progressWidth: CGFloat = 0
	@IBOutlet weak var scanViewOffset: NSLayoutConstraint!
	
	open class func scanner(_ dict: NSDictionary, closure:@escaping(String)->()) -> ScannerViewController?
	{
		let experience = Experience(json: JSON(dict))
		let scanner = ScannerViewController(experience: experience)
		scanner.returnClosure = closure;
		scanner.markerDetectionHandler = MarkerCodeDetectionHandler(experience: experience, closure: closure)
		return scanner
	}
	
	public init(experience: Experience)
	{
		super.init(nibName:"ScannerViewController", bundle:Bundle(identifier: "uk.ac.horizon.ArtcodesScanner"))
		self.experience = experience
	}

	public required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
	}
	
	open override func viewDidLoad()
	{
		super.viewDidLoad()
		if let name = experience.name
		{
			backButton.setTitle(name, for: UIControlState())
		}
		
		progressWidth = UIScreen.main.bounds.width
	}
	
	open override func viewDidAppear(_ animated: Bool)
	{
		setupCamera()
	}
	
	fileprivate func configureAnimation()
	{
		scanViewOffset.constant = -1
		
		view.layoutIfNeeded()
		scanViewOffset.constant = progressWidth
	
		UIView.animate(withDuration: 0.4, delay:0.4, options: [.curveLinear], animations: {
			
			self.view.layoutIfNeeded()
			
			}, completion: { animationFinished in
				self.configureAnimation()
		})
	}
	
	fileprivate func setupHelpAnimation()
	{
		DispatchQueue.main.async(execute: {
			
			// load frames as UIImages
			var animationImages: [UIImage] = []
			for frameName in self.helpFrameNames
			{
				if let animationFrame = UIImage(named: frameName, in: Bundle(identifier: "uk.ac.horizon.ArtcodesScanner"), compatibleWith: nil)
				{
					NSLog("Created animation frame '%@' from lib bundle", frameName)
					animationImages.append(animationFrame)
				}
				else if let animationFrame = UIImage(named: frameName)
				{
					NSLog("Created animation frame '%@' from app bundle", frameName)
					animationImages.append(animationFrame)
				}
				else
				{
					NSLog("Failed to create animation frame: %@", frameName)
				}
			}
			
			// show last frame for twice as long
			if (animationImages.count > 0)
			{
				animationImages.append(animationImages[animationImages.count-1])
			}
			
			self.helpAnimation.animationImages = animationImages
			self.helpAnimation.animationDuration = 0.5 * Double(animationImages.count)
			self.helpAnimation.startAnimating()
		})
	}
	
	@IBAction func backButtonPressed(_ sender: AnyObject)
	{
		if let nonNilClosure = returnClosure
		{
			// if used as library, notify caller that back was pressed
			nonNilClosure("BACK")
		}
		else if let nav = navigationController
		{
			nav.popViewController(animated: true)
		}
		else
		{
			presentingViewController?.dismiss(animated: true, completion: nil)
		}
	}

	open override func viewWillAppear(_ animated: Bool)
	{
		let value = UIInterfaceOrientation.portrait.rawValue
		UIDevice.current.setValue(value, forKey: "orientation")
		navigationController?.isNavigationBarHidden = true
	}

	func thumbnailViewGesture(_ gestureRecognizer: UIGestureRecognizer)
	{
		// translate from screen to camera coordinates
		let screenFrame: CGRect = UIScreen.main.bounds;
		let viewFrame: CGRect = self.thumbnailView.frame;
		let touchPoint: CGPoint = gestureRecognizer.location(in: self.thumbnailView)
		let focusPoint: CGPoint = CGPoint(x: (viewFrame.origin.y+touchPoint.y)/screenFrame.height, y: (viewFrame.width-touchPoint.x)/screenFrame.width)
		
		for inputObject in captureSession.inputs
		{
			if let aVCaptureDeviceInput = inputObject as? AVCaptureDeviceInput
			{
				
				if let device = aVCaptureDeviceInput.device
				{
					do
					{
						try device.lockForConfiguration()
						if device.isFocusPointOfInterestSupported {
							device.focusPointOfInterest = focusPoint
						}
						if device.isFocusModeSupported(.autoFocus)
						{
							device.focusMode = AVCaptureFocusMode.autoFocus
						}
						if device.isExposurePointOfInterestSupported {
							device.exposurePointOfInterest = focusPoint
							device.exposureMode = AVCaptureExposureMode.autoExpose
						}
						device.unlockForConfiguration()
					}
					catch let error as NSError
					{
						NSLog("error: %@", "\(error.localizedDescription)")
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
		
		for device in AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
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
							if (requestedAutoFocusMode == "tapToFocus" && captureDevice.isFocusModeSupported(AVCaptureFocusMode.autoFocus))
							{
								captureDevice.focusMode = .autoFocus
								// setup a listener for when the user taps the screen
								let gestureRecognizer: UIGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(thumbnailViewGesture));
								self.thumbnailView.addGestureRecognizer(gestureRecognizer);
								
								// tell frameProcessor when camera is focusing so it can skip those frames
								captureDevice.addObserver(frameProcessor!, forKeyPath:"adjustingFocus", options: NSKeyValueObservingOptions.new, context: nil)
								shouldRemoveAutofocusObserverOnExit = true
								focusHasBeenSet = true
								focusLabel.isHidden = false
							}
						}
					
						if (!focusHasBeenSet && captureDevice.isFocusModeSupported(AVCaptureFocusMode.continuousAutoFocus))
						{
							captureDevice.focusMode = .continuousAutoFocus
							focusHasBeenSet = true
						}
						
						if captureDevice.isExposureModeSupported(AVCaptureExposureMode.continuousAutoExposure)
						{
							captureDevice.exposureMode = .continuousAutoExposure
						}
						if captureDevice.isWhiteBalanceModeSupported(AVCaptureWhiteBalanceMode.continuousAutoWhiteBalance)
						{
							captureDevice.whiteBalanceMode = .continuousAutoWhiteBalance
						}
						
						if let useTorch = UserDefaults.standard.object(forKey: "torch_on_at_start") as? Bool
						{
							if useTorch
							{
								if captureDevice.isTorchAvailable
								{
									do {
										try captureDevice.setTorchModeOnWithLevel(1)
									}
									catch let error as NSError
									{
										NSLog("error: %@", "\(error.localizedDescription)")
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
						previewLayer?.frame = view.bounds
						previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
						//cameraView.layer.sublayers.removeAll(keepCapacity: true)
						cameraView.layer.addSublayer(previewLayer!)
						
						let settings = DetectionSettings(experience: experience!, handler: getMarkerDetectionHandler())
						frameProcessor?.overlay = overlayImage.layer
						frameProcessor?.createPipeline(experience!.pipeline, andSettings: settings)
						
						
						let videoOutput = AVCaptureVideoDataOutput()
						// Ask for the camera data in the format the first pipeline item uses.
						// In the future it might be faster to ask for YCbCr data and convert only the part of the image we need to BGR using cvtColor but there is no documentation on the data arrangement in the CbCr plane.
						videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
						if let firstImageProcessor = frameProcessor!.pipeline.first as? ImageProcessor
						{
							if firstImageProcessor.requiresBgraInput() || UserDefaults.standard.bool(forKey: "force_rgb_input")
							{
								videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: Int(kCVPixelFormatType_32BGRA)]
							}
						}
						videoOutput.alwaysDiscardsLateVideoFrames = true
						videoOutput.setSampleBufferDelegate(frameProcessor, queue: frameQueue)
							
						if captureSession.canAddOutput(videoOutput)
						{
							captureSession.addOutput(videoOutput)
						}
							
						captureSession.startRunning()
						//configureAnimation()
						
						if experience.name != nil && experience.name == "Artcodes"
						{
							setupHelpAnimation()
						}
						return
					}
					catch let error as NSError
					{
						NSLog("error: %@", "\(error.localizedDescription)")
					}
				}
			}
		}
	}
	
	@IBAction open func openAction(_ sender: AnyObject) {
	}
	
	open override var preferredStatusBarStyle : UIStatusBarStyle
	{
		return .lightContent
	}
	
	@IBAction func toggleFacing(_ sender: UIButton)
	{
		if facing == AVCaptureDevicePosition.back
		{
			facing = AVCaptureDevicePosition.front
			displayMenuText("Using front camera")
			sender.setImage(UIImage(named: "ic_camera_front", in: Bundle(identifier: "uk.ac.horizon.ArtcodesScanner"), compatibleWith: nil), for: UIControlState())
		}
		else
		{
			facing = AVCaptureDevicePosition.back
			displayMenuText("Using back camera")
			sender.setImage(UIImage(named: "ic_camera_rear", in: Bundle(identifier: "uk.ac.horizon.ArtcodesScanner"), compatibleWith: nil), for: UIControlState())
		}
		setupCamera()
	}
	
	@IBAction func toggleThreshold(_ sender: UIButton)
	{
		if frameProcessor!.settings.displayThreshold == 0
		{
			frameProcessor!.settings.displayThreshold = 1
			displayMenuText("Thresholding visible")
			sender.tintColor = UIColor.white
		}
		else
		{
			frameProcessor!.settings.displayThreshold = 0
			displayMenuText("Thresholding hidden")
			sender.tintColor = UIColor.lightGray
		}
	}
	
	@IBAction func toggleOutline(_ sender: UIButton)
	{
		if frameProcessor!.settings.displayOutline == 0
		{
			frameProcessor!.settings.displayOutline = 1
			sender.setImage(UIImage(named: "ic_border_outer", in: Bundle(identifier: "uk.ac.horizon.ArtcodesScanner"), compatibleWith: nil), for: UIControlState())
			sender.tintColor = UIColor.white
			displayMenuText("Marker outlined")
		}
		else if frameProcessor!.settings.displayOutline == 1
		{
			frameProcessor!.settings.displayOutline = 2
			sender.setImage(UIImage(named: "ic_border_all", in: Bundle(identifier: "uk.ac.horizon.ArtcodesScanner"), compatibleWith: nil), for: UIControlState())
			sender.tintColor = UIColor.white
			displayMenuText("Marker regions outlined")
		}
		else if frameProcessor!.settings.displayOutline == 2
		{
			frameProcessor!.settings.displayOutline = 0
			sender.setImage(UIImage(named: "ic_border_clear", in: Bundle(identifier: "uk.ac.horizon.ArtcodesScanner"), compatibleWith: nil), for: UIControlState())
			sender.tintColor = UIColor.lightGray
			displayMenuText("Marker outlines hidden")
		}
	}
	
	open func displayMenuText(_ text: String)
	{
		menuLabel.text = text
		//UIView.animateWithDuration(Double(0.5), animations: {
			self.menuLabelHeight.constant = 20
			self.menu.layoutIfNeeded()
		//})
		
		labelTimer?.invalidate()
		//labelTimer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: #selector(ScannerViewController.hideMenuText), userInfo: nil, repeats: true)
	}
	
	func hideMenuText()
	{
		//UIView.animateWithDuration(Double(0.5), animations: {
			self.menuLabelHeight.constant = 0
			self.menu.layoutIfNeeded()
		//})
	}
	
	@IBAction func toggleCode(_ sender: UIButton)
	{
		if frameProcessor!.settings.displayText == 0
		{
			frameProcessor!.settings.displayText = 1
			sender.tintColor = UIColor.white
			displayMenuText("Marker codes visible")
		}
		else
		{
			frameProcessor!.settings.displayText = 0
			sender.tintColor = UIColor.lightGray
			displayMenuText("Marker codes hidden")
		}
	}
	@IBAction func toggleTorch(_ sender: UIButton)
	{
		for inputObject in captureSession.inputs
		{
			if let aVCaptureDeviceInput = inputObject as? AVCaptureDeviceInput
			{
				
				if let captureDevice = aVCaptureDeviceInput.device
				{
					if captureDevice.isTorchAvailable
					{
						do {
							try captureDevice.lockForConfiguration()
							if captureDevice.isTorchActive
							{
								captureDevice.torchMode = .off
								sender.tintColor = UIColor.lightGray
								sender.setImage(UIImage(named: "ic_light_off", in: Bundle(identifier: "uk.ac.horizon.ArtcodesScanner"), compatibleWith: nil), for: UIControlState())
								displayMenuText("Torch off")
							}
							else
							{
								try captureDevice.setTorchModeOnWithLevel(1)
								sender.tintColor = UIColor.white
								sender.setImage(UIImage(named: "ic_light_on", in: Bundle(identifier: "uk.ac.horizon.ArtcodesScanner"), compatibleWith: nil), for: UIControlState())
								displayMenuText("Torch on")
								
							}
							captureDevice.unlockForConfiguration()
						}
						catch let error as NSError
						{
							NSLog("error: %@", "\(error.localizedDescription)")
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
	
	@IBAction open func takePicture(_ sender: AnyObject) {
	}
	
	open override var supportedInterfaceOrientations : UIInterfaceOrientationMask
	{
		return [UIInterfaceOrientationMask.portrait]
	}
	
	func makeCirclePath(_ origin: CGPoint, radius: CGFloat) -> CGPath
	{
		let size = radius * 2
		return UIBezierPath(roundedRect: CGRect(x: origin.x - radius, y: origin.y - radius, width: size, height: size), cornerRadius: radius).cgPath
	}
	
	@IBAction func showMenu(_ sender: AnyObject)
	{
		let origin = CGPoint(x: menuButton.frame.midX - menu.frame.origin.x, y: menuButton.frame.midY - menu.frame.origin.y);
		let mask = CAShapeLayer()
		mask.path = makeCirclePath(origin, radius: 0)
		mask.fillColor = UIColor.black.cgColor
	
		menu.layer.mask = mask
	
		CATransaction.begin()
		let animation = CABasicAnimation(keyPath: "path")
		animation.duration = 0.25
		animation.fillMode = kCAFillModeForwards
		animation.isRemovedOnCompletion = false
	
		let newPath = makeCirclePath(origin, radius:menu.bounds.width)
		animation.fromValue = mask.path
		animation.toValue = newPath
	
		CATransaction.setCompletionBlock() {
			self.menu.layer.mask = nil;
		}

		mask.add(animation, forKey:"path")
		CATransaction.commit()
	
		menu.isHidden = false
		menuButton.isHidden = true
	}
	
	@IBAction func hideMenu(_ sender: AnyObject)
	{
		let origin = CGPoint(x: menuButton.frame.midX - menu.frame.origin.x, y: menuButton.frame.midY - menu.frame.origin.y);
		let mask = CAShapeLayer()
		mask.path = makeCirclePath(origin, radius:menu.bounds.width)
		mask.fillColor = UIColor.black.cgColor
	
		menu.layer.mask = mask
	
		CATransaction.begin()
		let animation = CABasicAnimation(keyPath: "path")
		animation.duration = 0.25
		animation.fillMode = kCAFillModeForwards
		animation.isRemovedOnCompletion = false
	
		let newPath = makeCirclePath(origin, radius:0)
	
		animation.fromValue = mask.path
		animation.toValue = newPath
	
		weak var weakSelf: ScannerViewController? = self;
		CATransaction.setCompletionBlock() {
			weakSelf?.menu.isHidden = true
			weakSelf?.menuButton.isHidden = false
			weakSelf?.menu.layer.mask = nil
		}
		mask.add(animation, forKey:"path")
		CATransaction.commit()
	}
	
	open override func viewWillDisappear(_ animated: Bool)
	{
		NSLog("Scanner View Controller disappear")
		
		// This removes the frameProcessor from observing the auto-focus status (currently only used in tap to focus)
		// the if-statement and variable are required as if your addObserver/removeObserver calls don't match the app crashes
		if shouldRemoveAutofocusObserverOnExit
		{
			for inputObject in captureSession.inputs
			{
				if let aVCaptureDeviceInput = inputObject as? AVCaptureDeviceInput
				{
					if let captureDevice = aVCaptureDeviceInput.device
					{
						captureDevice.removeObserver(frameProcessor!, forKeyPath: "adjustingFocus")
					}
				}
			}
		}

		// TODO: Move to different thread (moving to frameQueue seems to prevent the camera stopping if a pipeline is set)
		//dispatch_async(frameQueue, {
			self.captureSession.stopRunning()
		//})
		

		let value = UIInterfaceOrientation.unknown.rawValue;
		UIDevice.current.setValue(value, forKey: "orientation")
		navigationController?.isNavigationBarHidden = false
	}
	
	open override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		self.markerDetectionHandler = nil
		self.returnClosure = nil
		
		self.frameProcessor = nil
		
		self.deviceInput = nil
		
		self.frameQueue = nil;
		
		self.labelTimer = nil;
		
		NSLog("### Scan view controller viewDidDisappear")
		
	}
	
	open func getMarkerDetectionHandler() -> MarkerDetectionHandler
	{
		if (self.markerDetectionHandler == nil)
		{
			self.markerDetectionHandler = MarkerCodeDetectionHandler(experience: self.experience)
			{ (code) in
					
			}
		}
		return self.markerDetectionHandler!
	}
	
	deinit {
		NSLog("*** Scan view controller deinit")
	}
}
