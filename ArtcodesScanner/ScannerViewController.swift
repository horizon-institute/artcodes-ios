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

open class ScannerViewController: UIViewController
{
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var overlayImage: UIImageView!
    
    @IBOutlet weak var menu: UIView!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var menuLabel: UILabel!
    @IBOutlet weak var menuLabelHeight: NSLayoutConstraint!
    
    @IBOutlet weak var viewfinderBottom: UIView!
    @IBOutlet public weak var actionButton: UIButton!
    @IBOutlet public weak var takePictureButton: UIButton!
    
    @IBOutlet public weak var thumbnailView: UIView!
    @IBOutlet weak var focusLabel: UILabel!
    
    var shouldRemoveAutofocusObserverOnExit = false
    
    
    @IBOutlet public weak var helpAnimation: UIImageView!
    let helpFrameNames: [String] = ["scan_help_animation_frame1","scan_help_animation_frame2","scan_help_animation_frame3","scan_help_animation_frame4","scan_help_animation_frame5","scan_help_animation_frame6","scan_help_animation_frame7"]
    
    public var markerDetectionHandler: MarkerDetectionHandler?
    
    var labelTimer: Timer? = Timer()
    let captureSession = AVCaptureSession()
    var captureDevice : AVCaptureDevice?
    var deviceInput: AVCaptureDeviceInput?
    var facing = AVCaptureDevice.Position.back
    var frameQueue = DispatchQueue(label: "Frame Processing Queue")
    
    var returnClosure: ((String)->())?
    
    public var experience: Experience!
    var frameProcessor: FrameProcessor? = FrameProcessor()
    
    private var progressWidth: CGFloat = 0
    @IBOutlet weak var scanViewOffset: NSLayoutConstraint!
    
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
       
        progressWidth = UIScreen.main.bounds.width
    }
    
    public override func viewDidAppear(_ animated: Bool)
    {
        setupCamera()
    }
    
    private func configureAnimation()
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
    
    private func setupHelpAnimation()
    {
        DispatchQueue.main.async {
            // load frames as UIImages
            var animationImages: [UIImage] = []
            for frameName in self.helpFrameNames
            {
                if let animationFrame = UIImage(named: frameName)
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
        }
    }
    
    open override func viewWillAppear(_ animated: Bool)
    {
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        //navigationController?.isNavigationBarHidden = true
    }
    
    @objc func thumbnailViewGesture(gestureRecognizer: UIGestureRecognizer)
    {
        // translate from screen to camera coordinates
        let screenFrame: CGRect = UIScreen.main.bounds;
        let viewFrame: CGRect = self.thumbnailView.frame;
        let touchPoint: CGPoint = gestureRecognizer.location(in: self.thumbnailView)
        let focusPoint: CGPoint = CGPointMake((viewFrame.origin.y+touchPoint.y)/screenFrame.height, (viewFrame.width-touchPoint.x)/screenFrame.width)
        
        for inputObject in captureSession.inputs
        {
            if let aVCaptureDeviceInput = inputObject as? AVCaptureDeviceInput
            {
                let device = aVCaptureDeviceInput.device
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
            }
        }
    }
    
    
    func setupCamera()
    {
            // TODO Preset?
            self.captureSession.stopRunning()
            self.captureSession.sessionPreset = AVCaptureSession.Preset.hd1280x720
            if let input = self.deviceInput
            {
                self.captureSession.removeInput(input)
            }
            
            for device in AVCaptureDevice.devices(for: AVMediaType.video)
            {
                let captureDevice = device as AVCaptureDevice
                if(captureDevice.position == self.facing)
                {
                    do
                    {
                        try captureDevice.lockForConfiguration()
                        
                        var focusHasBeenSet = false
                        if let requestedAutoFocusMode = self.experience.requestedAutoFocusMode
                        {
                            if (requestedAutoFocusMode == "tapToFocus" && captureDevice.isFocusModeSupported(AVCaptureDevice.FocusMode.autoFocus))
                            {
                                captureDevice.focusMode = .autoFocus
                                // setup a listener for when the user taps the screen
                                let gestureRecognizer: UIGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(self.thumbnailViewGesture));
                                self.thumbnailView.addGestureRecognizer(gestureRecognizer);
                                
                                // tell frameProcessor when camera is focusing so it can skip those frames
                                captureDevice.addObserver(self.frameProcessor!, forKeyPath:"adjustingFocus", options: NSKeyValueObservingOptions.new, context: nil)
                                self.shouldRemoveAutofocusObserverOnExit = true
                                focusHasBeenSet = true
                                self.focusLabel.isHidden = false
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
                        
                        let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
                        self.deviceInput = deviceInput
                        
                        if self.captureSession.canAddInput(deviceInput)
                        {
                            self.captureSession.addInput(deviceInput)
                        }
                        
                        let previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                        previewLayer.frame = self.view.bounds
                        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                        //cameraView.layer.sublayers.removeAll(keepCapacity: true)
                        self.cameraView.layer.addSublayer(previewLayer)
                        
                        let settings = DetectionSettings(experience: self.experience!, handler: self.getMarkerDetectionHandler())
                        self.frameProcessor?.overlay = self.overlayImage.layer
                        self.frameProcessor?.createPipeline(self.experience.pipeline ?? [], andSettings: settings)                        
                        
                        let videoOutput = AVCaptureVideoDataOutput()
                        // Ask for the camera data in the format the first pipeline item uses.
                        // In the future it might be faster to ask for YCbCr data and convert only the part of the image we need to BGR using cvtColor but there is no documentation on the data arrangement in the CbCr plane.
                        videoOutput.videoSettings = [String(describing: kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
                        if let firstImageProcessor = self.frameProcessor!.pipeline.first
                        {
                            if firstImageProcessor.requiresBgraInput || UserDefaults.standard.bool(forKey: "force_rgb_input")
                            {
                                videoOutput.videoSettings = [String(describing: kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_32BGRA)]
                            }
                        }
                        videoOutput.alwaysDiscardsLateVideoFrames = true
                        videoOutput.setSampleBufferDelegate(self.frameProcessor, queue: self.frameQueue)
                        
                        if self.captureSession.canAddOutput(videoOutput)
                        {
                            self.captureSession.addOutput(videoOutput)
                        }
                        
                        frameQueue.async {
                            self.captureSession.startRunning()
                        }
                        //configureAnimation()
                        
                        if self.experience.name != nil && self.experience.name == "Artcodes"
                        {
                            self.setupHelpAnimation()
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
    
    @IBAction open func openAction(_ sender: Any) {
    }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle
    {
        return .lightContent
    }
    
    @IBAction func toggleFacing(_ sender: UIButton)
    {
        if facing == AVCaptureDevice.Position.back
        {
            facing = AVCaptureDevice.Position.front
            displayMenuText(text: "Using front camera")
            sender.setImage(UIImage(named: "ic_camera_front", in: Bundle(identifier: "uk.ac.horizon.ArtcodesScanner"), compatibleWith: nil), for: .normal)
        }
        else
        {
            facing = AVCaptureDevice.Position.back
            displayMenuText(text: "Using back camera")
            sender.setImage(UIImage(named: "ic_camera_rear"), for: .normal)
        }
        setupCamera()
    }
    
    @IBAction func toggleThreshold(_ sender: UIButton)
    {
        if frameProcessor!.settings.displayThreshold == 0
        {
            frameProcessor!.settings.displayThreshold = 1
            displayMenuText(text: "Thresholding visible")
            sender.tintColor = UIColor.white
        }
        else
        {
            frameProcessor!.settings.displayThreshold = 0
            displayMenuText(text: "Thresholding hidden")
            sender.tintColor = UIColor.lightGray
        }
    }
    
    @IBAction func toggleOutline(_ sender: UIButton)
    {
        if frameProcessor!.settings.displayOutline == 0
        {
            frameProcessor!.settings.displayOutline = 1
            sender.setImage(UIImage(named: "ic_border_outer"), for: .normal)
            sender.tintColor = UIColor.white
            displayMenuText(text: "Marker outlined")
        }
        else if frameProcessor!.settings.displayOutline == 1
        {
            frameProcessor!.settings.displayOutline = 2
            sender.setImage(UIImage(named: "ic_border_all"), for: .normal)
            sender.tintColor = UIColor.white
            displayMenuText(text: "Marker regions outlined")
        }
        else if frameProcessor!.settings.displayOutline == 2
        {
            frameProcessor!.settings.displayOutline = 0
            sender.setImage(UIImage(named: "ic_border_clear"), for: .normal)
            sender.tintColor = UIColor.lightGray
            displayMenuText(text: "Marker outlines hidden")
        }
    }
    
    public func displayMenuText(text: String)
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
            displayMenuText(text: "Marker codes visible")
        }
        else
        {
            frameProcessor!.settings.displayText = 0
            sender.tintColor = UIColor.lightGray
            displayMenuText(text: "Marker codes hidden")
        }
    }
    @IBAction func toggleTorch(_ sender: UIButton)
    {
        for inputObject in captureSession.inputs
        {
            if let aVCaptureDeviceInput = inputObject as? AVCaptureDeviceInput
            {
                let captureDevice = aVCaptureDeviceInput.device
                if captureDevice.isTorchAvailable
                {
                    do {
                        try captureDevice.lockForConfiguration()
                        if captureDevice.isTorchActive
                        {
                            captureDevice.torchMode = .off
                            sender.tintColor = UIColor.lightGray
                            sender.setImage(UIImage(named: "ic_light_off", in: Bundle(identifier: "uk.ac.horizon.ArtcodesScanner"), compatibleWith: nil), for: .normal)
                            displayMenuText(text: "Torch off")
                        }
                        else
                        {
                            try captureDevice.setTorchModeOn(level: 1)
                            sender.tintColor = UIColor.white
                            sender.setImage(UIImage(named: "ic_light_on"), for: .normal)
                            displayMenuText(text: "Torch on")
                            
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
                    displayMenuText(text: "Torch not available")
                }
            }
        }
    }
    
    @IBAction open func takePicture(_ sender: Any) {
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask
    {
        return [UIInterfaceOrientationMask.portrait]
    }
    
    func makeCirclePath(origin: CGPoint, radius: CGFloat) -> CGPath
    {
        let size = radius * 2
        return UIBezierPath(roundedRect: CGRect(x: origin.x - radius, y: origin.y - radius, width: size, height: size), cornerRadius: radius).cgPath
    }
    
    @IBAction func showMenu(_ sender: Any)
    {
        let origin = CGPointMake(CGRectGetMidX(menuButton.frame) - menu.frame.origin.x, CGRectGetMidY(menuButton.frame) - menu.frame.origin.y);
        let mask = CAShapeLayer()
        mask.path = makeCirclePath(origin: origin, radius: 0)
        mask.fillColor = UIColor.black.cgColor
        
        menu.layer.mask = mask
        
        CATransaction.begin()
        let animation = CABasicAnimation(keyPath: "path")
        animation.duration = 0.25
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.isRemovedOnCompletion = false
        
        let newPath = makeCirclePath(origin: origin, radius:menu.bounds.width)
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
    
    @IBAction func hideMenu(_ sender: Any)
    {
        let origin = CGPointMake(CGRectGetMidX(menuButton.frame) - menu.frame.origin.x, CGRectGetMidY(menuButton.frame) - menu.frame.origin.y);
        let mask = CAShapeLayer()
        mask.path = makeCirclePath(origin: origin, radius:menu.bounds.width)
        mask.fillColor = UIColor.black.cgColor
        
        menu.layer.mask = mask
        
        CATransaction.begin()
        let animation = CABasicAnimation(keyPath: "path")
        animation.duration = 0.25
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.isRemovedOnCompletion = false
        
        let newPath = makeCirclePath(origin: origin, radius:0)
        
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
    
    public override func viewWillDisappear(_ animated: Bool)
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
                    aVCaptureDeviceInput.device.removeObserver(frameProcessor!, forKeyPath: "adjustingFocus")
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
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.markerDetectionHandler = nil
        self.returnClosure = nil
        
        self.frameProcessor = nil
        self.deviceInput = nil
        
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
