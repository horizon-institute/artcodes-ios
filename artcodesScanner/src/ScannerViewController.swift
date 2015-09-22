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
import UIKit
import AVFoundation

public class ScannerViewController: UIViewController
{
	@IBOutlet weak var cameraView: UIView!
	@IBOutlet weak var overlayImage: UIImageView!
	@IBOutlet weak var statusText: UILabel!

	@IBOutlet weak var menu: UIView!
	@IBOutlet weak var menuButton: UIButton!

	let captureSession = AVCaptureSession()
	var captureDevice : AVCaptureDevice?
	var facing = AVCaptureDevicePosition.Back
	let frameQueue = dispatch_queue_create("Frame Processing Queue", DISPATCH_QUEUE_SERIAL)
	
	public var experience: Experience!
	let frameProcessor = FrameProcessor()
	
	public init()
	{
		super.init(nibName:"ScannerViewController", bundle:NSBundle(identifier: "uk.ac.horizon.artcodesScanner"))
	}

	public required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
	}
	
	public override func viewDidLoad()
	{
		super.viewDidLoad()
	}
	
	public override func viewDidAppear(animated: Bool)
	{
		setupCamera()
	}
	
	@IBAction func backButtonPressed(sender: AnyObject)
	{
		navigationController?.popViewControllerAnimated(true)
	}

	public override func viewWillAppear(animated: Bool)
	{
		navigationController?.navigationBarHidden = true
	}

	func setupCamera()
	{
		// TODO Preset?
		captureSession.stopRunning()
		captureSession.sessionPreset = AVCaptureSessionPresetiFrame960x540
		
		for device in AVCaptureDevice.devices()
		{
			if (device.hasMediaType(AVMediaTypeVideo))
			{
				if(device.position == facing)
				{
					if let captureDevice = device as? AVCaptureDevice
					{
						do {
							try captureDevice.lockForConfiguration()
						} catch _ {
						}
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
						
						do
						{
							let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
							
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
							frameProcessor.settings = experience.markerSettings
							videoOutput.setSampleBufferDelegate(frameProcessor, queue: frameQueue)
							NSLog("Started processing, in theory")
							
							if captureSession.canAddOutput(videoOutput)
							{
								captureSession.addOutput(videoOutput)
							}
							
							captureSession.startRunning()
						}
						catch let error as NSError
						{
							NSLog("error: \(error.localizedDescription)")
						}
					}
				}
			}
		}
	}
	
	public override func preferredStatusBarStyle() -> UIStatusBarStyle
	{
		return .LightContent
	}
	
	func makeCirclePath(location: CGPoint, radius:CGFloat) -> CGPathRef
	{
		let path = UIBezierPath()
		path.addArcWithCenter(location, radius: radius, startAngle: CGFloat(0), endAngle: CGFloat(M_PI * 2.0), clockwise: true)
		return path.CGPath
	}
	
	@IBAction func toggleFacing(sender: AnyObject)
	{
		if facing == AVCaptureDevicePosition.Back
		{
			facing = AVCaptureDevicePosition.Front
		}
		else
		{
			facing = AVCaptureDevicePosition.Back
		}
		setupCamera()
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
	
		let newPath = makeCirclePath(origin, radius:CGRectGetWidth(self.menu.bounds) + 20)
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
		mask.path = makeCirclePath(origin, radius:CGRectGetWidth(menu.bounds) + 20)
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
		if let navigation = navigationController
		{
			navigation.navigationBarHidden = false
		}
	}
}
