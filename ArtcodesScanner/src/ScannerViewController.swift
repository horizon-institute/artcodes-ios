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

open class ScannerViewController: UIViewController, FocusCallback
{
	@IBOutlet weak var cameraView: UIView!
	@IBOutlet weak var overlayImage: UIImageView!

	@IBOutlet weak var backButton: UIButton!
	@IBOutlet weak var menu: UIView!
	@IBOutlet weak var menuButton: UIButton!
	@IBOutlet weak var menuLabel: UILabel!
	@IBOutlet weak var menuLabelHeight: NSLayoutConstraint!

	@IBOutlet weak var viewfinderTop: UIView!
	@IBOutlet weak var viewfinderBottom: UIView!
	@IBOutlet open weak var actionButton: UIButton!
	@IBOutlet open weak var actionButtonContainer: UIView!
	@IBOutlet weak var actionButtonBackground: UIView!
	@IBOutlet open weak var takePictureButton: UIButton!
	
	@IBOutlet weak var alternativeLayoutContainer: UIView!
	@IBOutlet weak var alternativeLayoutTitle: UILabel!
	@IBOutlet weak var alternativeLayoutDesc: UILabel!
	
	@IBOutlet open weak var thumbnailView: UIView!
	@IBOutlet weak var focusLabel: UILabel!
	
	fileprivate var action: Action?
	
	@objc var shouldRemoveAutofocusObserverOnExit = false
	
	
	@IBOutlet open weak var helpAnimation: UIImageView!
	@objc let helpFrameNames: [String] = ["scan_help_animation_frame1","scan_help_animation_frame2","scan_help_animation_frame3","scan_help_animation_frame4","scan_help_animation_frame5","scan_help_animation_frame6","scan_help_animation_frame7"]
	
	@objc open var markerDetectionHandler: MarkerDetectionHandler?
	
	@objc var labelTimer: Timer? = Timer()
	@objc let captureSession = AVCaptureSession()
	@objc var captureDevice : AVCaptureDevice?
	@objc var deviceInput: AVCaptureDeviceInput?
	@objc var facing = AVCaptureDevice.Position.back
	@objc var frameQueue: DispatchQueue? = DispatchQueue(label: "Frame Processing Queue", attributes: [])
	
	@objc var returnClosure: ((String)->())?
	
	@objc open var experience: Experience!
	@objc open var frameProcessor: FrameProcessor? = FrameProcessor()
	
	fileprivate var progressWidth: CGFloat = 0
	@IBOutlet weak var scanViewOffset: NSLayoutConstraint!
	
	@objc open class func scanner(_ dict: NSDictionary, closure:@escaping(String)->()) -> ScannerViewController?
	{
		let experience = Experience(json: JSON(dict))
		let scanner = ScannerViewController(experience: experience)
		scanner.returnClosure = closure;
		if (experience.openWithoutUserInput ?? true)
		{
			scanner.markerDetectionHandler = MarkerCodeDetectionHandler(experience: experience, closure: closure)
		}
		else
		{
			weak var weakScanner: ScannerViewController? = scanner;
			scanner.markerDetectionHandler = MarkerCodeDetectionHandler(experience: experience)
			{ (code) in
				if let weakScanner2 = weakScanner
				{
					for action in experience.actions
					{
						if action.codes.contains(code)
						{
							weakScanner2.action = action
							break
						}
					}
					weakScanner2.showAction()
				}
			}
		}
		return scanner
	}
	
	@objc public init(experience: Experience)
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
			backButton.setTitle(name, for: UIControl.State())
		}
		
		progressWidth = UIScreen.main.bounds.width
		
		setExperienceStyle()
	}
	
	fileprivate func uiColorFrom(_ str: String, defaultAlpha: Float) -> UIColor
	{
		// from: https://gist.github.com/benhurott/d0ec9b3eac25b6325db32b8669196140
		let hex = str.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
		var int = UInt32()
		Scanner(string: hex).scanHexInt32(&int)
		let a, r, g, b: UInt32
		let defaultAlphaInt: UInt32 = UInt32(defaultAlpha * 255)
		switch hex.count {
		case 3: // RGB (12-bit)
			(a, r, g, b) = (defaultAlphaInt, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
		case 6: // RGB (24-bit)
			(a, r, g, b) = (defaultAlphaInt, int >> 16, int >> 8 & 0xFF, int & 0xFF)
		case 8: // ARGB (32-bit)
			(a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
		default:
			(a, r, g, b) = (defaultAlphaInt, 0, 0, 0)
		}
		return UIColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
	}
	
	// This function sets the colors of the scan screen (only if the experience contains colors).
	@objc open func setExperienceStyle()
	{
		self.actionButtonBackground.layer.cornerRadius = 3
		self.actionButton.titleLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
		self.actionButton.titleLabel?.textAlignment = NSTextAlignment.center

		self.actionButton.sizeToFit()
		
		if let experience = self.experience
		{
			if let backgroundColorStr = experience.backgroundColor
			{
				let backgroundColor: UIColor = uiColorFrom(backgroundColorStr, defaultAlpha: 0.7)
				
				
				self.viewfinderTop.backgroundColor = backgroundColor
				self.viewfinderBottom.backgroundColor = backgroundColor
			}
			
			if let foregroundColorStr = experience.foregroundColor
			{
				let foregroundColor: UIColor = uiColorFrom(foregroundColorStr, defaultAlpha: 1.0)
				self.backButton.titleLabel?.textColor = foregroundColor
				self.backButton.imageView?.tintColor = foregroundColor
				self.backButton.tintColor = foregroundColor
				self.backButton.setTitleColor(foregroundColor, for: UIControl.State.normal)
				
				self.alternativeLayoutTitle.textColor = foregroundColor
				self.alternativeLayoutDesc.textColor = foregroundColor
			}
			
			if let backgroundColorStr = experience.highlightBackgroundColor
			{
				if let foregroundColorStr = experience.highlightForegroundColor
				{
					let backgroundColor = uiColorFrom(backgroundColorStr, defaultAlpha: 1.0)
					let foregroundColor = uiColorFrom(foregroundColorStr, defaultAlpha: 1.0)
					
					self.actionButtonBackground.backgroundColor = backgroundColor
					self.actionButton.tintColor = foregroundColor
				}
			}
			
			
			if (experience.scanScreenTextTitle != nil || experience.scanScreenTextDesciption != nil)
			{
				self.alternativeLayoutTitle.text = experience.scanScreenTextTitle ?? ""
				self.alternativeLayoutDesc.text = experience.scanScreenTextDesciption ?? ""
				
				self.alternativeLayoutContainer.isHidden = false
				
				backButton.setTitle("", for: UIControl.State())
			}
			
		}
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

	@objc func thumbnailViewGesture(_ gestureRecognizer: UIGestureRecognizer)
	{
		// translate from screen to camera coordinates
		let screenFrame: CGRect = UIScreen.main.bounds;
		let viewFrame: CGRect = self.thumbnailView.frame;
		let touchPoint: CGPoint = gestureRecognizer.location(in: self.thumbnailView)
		let focusPoint: CGPoint = CGPoint(x: (viewFrame.origin.y+touchPoint.y)/screenFrame.height, y: (viewFrame.width-touchPoint.x)/screenFrame.width)
		print("point: \(focusPoint.x), \(focusPoint.y)")
		self.focusOnPoint(focusPoint)
	}
	public func focusOnCenter()
	{	
		let screenFrame: CGRect = UIScreen.main.bounds;
		let viewFrame: CGRect = self.thumbnailView.frame;
		let touchPoint: CGPoint = CGPoint(x: viewFrame.height/2.0, y: viewFrame.width/2.0)
		let focusPoint: CGPoint = CGPoint(x: (viewFrame.origin.y+touchPoint.y)/screenFrame.height, y: (viewFrame.width-touchPoint.x)/screenFrame.width)
		print("point: \(focusPoint.x), \(focusPoint.y)")
		self.focusOnPoint(focusPoint)
	}
	@objc func focusOnPoint(_ focusPoint: CGPoint)
	{
	
		for inputObject in captureSession.inputs
		{
			if let aVCaptureDeviceInput = inputObject as? AVCaptureDeviceInput
			{
				
				//if let
                let device = aVCaptureDeviceInput.device
				//{
					do
					{
						try device.lockForConfiguration()
						if device.isFocusPointOfInterestSupported {
							device.focusPointOfInterest = focusPoint
						}
						if device.isFocusModeSupported(.autoFocus)
						{
                            device.focusMode = AVCaptureDevice.FocusMode.autoFocus
						}
						if device.isExposurePointOfInterestSupported {
							device.exposurePointOfInterest = focusPoint
                            device.exposureMode = AVCaptureDevice.ExposureMode.autoExpose
						}
						device.unlockForConfiguration()
					}
					catch let error as NSError
					{
						NSLog("error: %@", "\(error.localizedDescription)")
					}
				//}
			}
		}
	}

	
	@objc func setupCamera()
	{
		// TODO Preset?
		captureSession.stopRunning()
		captureSession.sessionPreset = AVCaptureSession.Preset(rawValue: convertFromAVCaptureSessionPreset(AVCaptureSession.Preset.hd1280x720))
		if let input = deviceInput
		{
			captureSession.removeInput(input)
		}
		
		for device in AVCaptureDevice.devices(for: AVMediaType(rawValue: convertFromAVMediaType(AVMediaType.video)))
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
							if ((requestedAutoFocusMode == "tapToFocus" || requestedAutoFocusMode == "blurScore") && captureDevice.isFocusModeSupported(AVCaptureDevice.FocusMode.autoFocus))
							{
								captureDevice.focusMode = .autoFocus
								// setup a listener for when the user taps the screen
								let gestureRecognizer: UIGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(thumbnailViewGesture));
								self.thumbnailView.addGestureRecognizer(gestureRecognizer);
								
								// tell frameProcessor when camera is focusing so it can skip those frames
								captureDevice.addObserver(frameProcessor!, forKeyPath:"adjustingFocus", options: NSKeyValueObservingOptions.new, context: nil)
								shouldRemoveAutofocusObserverOnExit = true
								focusHasBeenSet = true
								if (requestedAutoFocusMode == "tapToFocus")
								{
									focusLabel.isHidden = false
								}
							}
						}
					
						if (!focusHasBeenSet && captureDevice.isFocusModeSupported(AVCaptureDevice.FocusMode.continuousAutoFocus))
						{
							captureDevice.focusMode = .continuousAutoFocus
							focusHasBeenSet = true
						}
						
						if captureDevice.isExposureModeSupported(AVCaptureDevice.ExposureMode.continuousAutoExposure)
						{
							captureDevice.exposureMode = .continuousAutoExposure
						}
						if captureDevice.isWhiteBalanceModeSupported(AVCaptureDevice.WhiteBalanceMode.continuousAutoWhiteBalance)
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
										try captureDevice.setTorchModeOn(level: 1)
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
						
                        if captureSession.canAddInput(deviceInput!)
						{
                            captureSession.addInput(deviceInput!)
						}
						
						let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
						previewLayer.frame = cameraView.bounds
						previewLayer.videoGravity = AVLayerVideoGravity(rawValue: convertFromAVLayerVideoGravity(AVLayerVideoGravity.resizeAspectFill))
						//cameraView.layer.sublayers.removeAll(keepCapacity: true)
						cameraView.layer.addSublayer(previewLayer)
						
						let settings = DetectionSettings(experience: experience!, handler: getMarkerDetectionHandler())
						frameProcessor?.overlay = overlayImage.layer
						frameProcessor?.focusCallback = self
						frameProcessor?.createPipeline(experience!.pipeline, andSettings: settings)
						
						
						let videoOutput = AVCaptureVideoDataOutput()
						// Ask for the camera data in the format the first pipeline item uses.
						// In the future it might be faster to ask for YCbCr data and convert only the part of the image we need to BGR using cvtColor but there is no documentation on the data arrangement in the CbCr plane.
						videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)] as! [String : Any]
						if let firstImageProcessor = frameProcessor!.pipeline.first as? ImageProcessor
						{
							if firstImageProcessor.requiresBgraInput() || UserDefaults.standard.bool(forKey: "force_rgb_input")
							{
								videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: Int(kCVPixelFormatType_32BGRA)] as! [String : Any]
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
	
	
	@objc func showAction()
	{
		DispatchQueue.main.async(execute: {
			if let title = self.action?.name
			{
				self.actionButton.setTitle(title, for: .normal)
			}
			else if let url = self.action?.url
			{
				self.actionButton.setTitle(url, for: .normal)
			}
			else if let code = self.action?.codes[0]
			{
				self.actionButton.setTitle(code, for: .normal)
			}
			else
			{
				return
			}
			self.actionButtonContainer.isHidden = false
			self.helpAnimation.isHidden = true
		})
	}
	
	@objc func hideAction()
	{
		DispatchQueue.main.async(execute: {
			self.actionButtonContainer.isHidden = true
		})
	}
	
	@IBAction open func openAction(_ sender: AnyObject) {
		if let action = self.action
		{
			self.returnClosure?(action.codes[0]);
		}
	}
	
	open override var preferredStatusBarStyle : UIStatusBarStyle
	{
		return .lightContent
	}
	
	@IBAction func toggleFacing(_ sender: UIButton)
	{
		if facing == AVCaptureDevice.Position.back
		{
			facing = AVCaptureDevice.Position.front
			displayMenuText("Using front camera")
			sender.setImage(UIImage(named: "ic_camera_front", in: Bundle(identifier: "uk.ac.horizon.ArtcodesScanner"), compatibleWith: nil), for: UIControl.State())
		}
		else
		{
			facing = AVCaptureDevice.Position.back
			displayMenuText("Using back camera")
			sender.setImage(UIImage(named: "ic_camera_rear", in: Bundle(identifier: "uk.ac.horizon.ArtcodesScanner"), compatibleWith: nil), for: UIControl.State())
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
			sender.setImage(UIImage(named: "ic_border_outer", in: Bundle(identifier: "uk.ac.horizon.ArtcodesScanner"), compatibleWith: nil), for: UIControl.State())
			sender.tintColor = UIColor.white
			displayMenuText("Marker outlined")
		}
		else if frameProcessor!.settings.displayOutline == 1
		{
			frameProcessor!.settings.displayOutline = 2
			sender.setImage(UIImage(named: "ic_border_all", in: Bundle(identifier: "uk.ac.horizon.ArtcodesScanner"), compatibleWith: nil), for: UIControl.State())
			sender.tintColor = UIColor.white
			displayMenuText("Marker regions outlined")
		}
		else if frameProcessor!.settings.displayOutline == 2
		{
			frameProcessor!.settings.displayOutline = 0
			sender.setImage(UIImage(named: "ic_border_clear", in: Bundle(identifier: "uk.ac.horizon.ArtcodesScanner"), compatibleWith: nil), for: UIControl.State())
			sender.tintColor = UIColor.lightGray
			displayMenuText("Marker outlines hidden")
		}
	}
	
	@objc open func displayMenuText(_ text: String)
	{
		menuLabel.text = text
		//UIView.animateWithDuration(Double(0.5), animations: {
			self.menuLabelHeight.constant = 20
			self.menu.layoutIfNeeded()
		//})
		
		labelTimer?.invalidate()
		//labelTimer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: #selector(ScannerViewController.hideMenuText), userInfo: nil, repeats: true)
	}
	
	@objc func hideMenuText()
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
				
				//if let
                let captureDevice = aVCaptureDeviceInput.device
				//{
					if captureDevice.isTorchAvailable
					{
						do {
							try captureDevice.lockForConfiguration()
							if captureDevice.isTorchActive
							{
								captureDevice.torchMode = .off
								sender.tintColor = UIColor.lightGray
								sender.setImage(UIImage(named: "ic_light_off", in: Bundle(identifier: "uk.ac.horizon.ArtcodesScanner"), compatibleWith: nil), for: UIControl.State())
								displayMenuText("Torch off")
							}
							else
							{
								try captureDevice.setTorchModeOn(level: 1)
								sender.tintColor = UIColor.white
								sender.setImage(UIImage(named: "ic_light_on", in: Bundle(identifier: "uk.ac.horizon.ArtcodesScanner"), compatibleWith: nil), for: UIControl.State())
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
				//}
			}
		}
	}
	
	@IBAction open func takePicture(_ sender: AnyObject) {
	}
	
	open override var supportedInterfaceOrientations : UIInterfaceOrientationMask
	{
		return [UIInterfaceOrientationMask.portrait]
	}
	
	@objc func makeCirclePath(_ origin: CGPoint, radius: CGFloat) -> CGPath
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
		animation.fillMode = CAMediaTimingFillMode.forwards
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
		animation.fillMode = CAMediaTimingFillMode.forwards
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
					//if let
                    let captureDevice = aVCaptureDeviceInput.device
					//{
						captureDevice.removeObserver(frameProcessor!, forKeyPath: "adjustingFocus")
					//}
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
	
	@objc open func getMarkerDetectionHandler() -> MarkerDetectionHandler
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

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVCaptureSessionPreset(_ input: AVCaptureSession.Preset) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVMediaType(_ input: AVMediaType) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVLayerVideoGravity(_ input: AVLayerVideoGravity) -> String {
	return input.rawValue
}
