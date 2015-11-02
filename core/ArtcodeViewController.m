/*
 * Aestheticodes recognises a different marker scheme that allows the
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
#import "ArtcodeViewController.h"
#import "MarkerCode.h"
#import "Experience.h"
#import "Marker.h"
#import "ACXMarkerThumbnail.h"
#import "ACXImageProcessor.h"

@interface ArtcodeViewController ()
@property (nonatomic) NSString* selected;

@property (retain) NSMutableArray *historyThumbnails;
@property (retain) NSMutableArray *historyThumbnailViews;
@end

@implementation ArtcodeViewController

-(id)initWithExperience:(Experience*)experience delegate:(id<ArtcodeDelegate>)delegate
{
	for(NSBundle* bundle in [NSBundle allBundles])
	{
		NSLog(@"Bundle %@", bundle);
		NSLog(@"Resource path %@", [bundle pathForResource:@"artcodeReader" ofType:@"xib"]);
	}
	
	self = [super initWithNibName:@"artcodeReader" bundle:nil];
	if (self != nil)
	{
		self.experience = [[ExperienceController alloc] init];
		self.experience.item = experience;
		
		self.delegate = delegate;
	}
	return self;
}

-(void)viewDidLoad
{
	[super viewDidLoad];
	
	if(!self.experience)
	{
		self.experience = [[ExperienceController alloc] init];
	}
	[self.experience addListener:self];
	
	self.camera = [[MarkerCamera alloc] init];
	self.camera.delegate = self;
	
	self.menu.bounds = CGRectMake(self.menu.bounds.origin.x, self.menu.bounds.origin.y, self.menu.bounds.size.width, 0);
	
	self.markerSelection = [[MarkerSelection  alloc] init];
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	self.camera.experience = self.experience;
	[self.camera start:self.imageView];
	
	// adjust the size of the viewfinder depending on how much of the camera feed we are using:
	CGSize size = [[UIScreen mainScreen] bounds].size;
	float topAndBottomBarSize = 0;
	
	if(self.camera.fullSizeViewFinder)
	{
		topAndBottomBarSize = (size.height - size.width)/2.0;
		self.viewfinderLeftWidth.constant = 0;
		self.viewfinderRightWidth.constant = 0;
	}
	else
	{
		topAndBottomBarSize = (size.height - size.width/1.4)/2.0;
		float leftAndRightBarSize = (size.width - (size.width / 1.4))/2.0;
		self.viewfinderLeftWidth.constant= leftAndRightBarSize;
		self.viewfinderRightWidth.constant = leftAndRightBarSize;
	}
	
	// minimum sizes insure there is room for the toolbar and mode picker/text
	self.viewfinderTopHeight.constant = topAndBottomBarSize < 60 ? 60 : topAndBottomBarSize;
	self.viewfinderBottomHeight.constant = topAndBottomBarSize < 60 ? 60 : topAndBottomBarSize;
	
	//self.menu.bounds = CGRectMake(self.menu.bounds.origin.x, self.menu.bounds.origin.y, self.menu.bounds.size.width, 0);
	
	[self.view layoutSubviews];
	
	// Ask the system to notify us when in foreground: (removed in [self viewWillDisappear])
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(applicationEnteredForeground:)
												 name:UIApplicationWillEnterForegroundNotification
											   object:nil];
	// Ask the system to notify us when in background: (removed in [self viewWillDisappear])
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(applicationEnteredBackground:)
												 name:UIApplicationDidEnterBackgroundNotification
											   object:nil];
}

-(void)experienceChanged:(Experience *)experience
{
	self.camera.markerCodeFactory = [experience getMarkerCodeFactory];
	[self.camera setImageProcessor:[[ACXImageProcessor alloc] initWithComponents:[ACXImageProcessor parseComponentsFrom:[experience imageProcessingComponents]]]];
	[self markerChanged:self.selected];
}

/*!
 Called when the system tells us the app is in the forground
 */
- (void)applicationEnteredForeground:(NSNotification *)notification
{
	NSLog(@"Application entered foreground");
	[self.camera start:self.imageView];
}
/*!
 Called when the system tells us the app is in the background
 */
- (void)applicationEnteredBackground:(NSNotification *)notification
{
	NSLog(@"Application entered background");
	[self.camera stop];
}

-(void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
	
	self.navigationController.navigationBarHidden = false;
	[self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
	
	[self.camera stop];
}

-(IBAction)switchMarkerDisplay:(id)sender
{
	self.camera.displayMarker = (self.camera.displayMarker % 4) + 1;
	[self updateMenu];
}

- (IBAction)back:(id)sender
{
	[self.camera stop];
	[self.navigationController popViewControllerAnimated:true];
}

-(IBAction)switchThresholdDisplay:(id)sender
{
	self.camera.cameraFeedDisplayMode = (self.camera.cameraFeedDisplayMode+1) % 3;
	[self updateMenu];
}

- (IBAction)switchCamera:(id)sender
{
	self.camera.rearCamera = !self.camera.rearCamera;
	[self updateMenu];
}

- (CGPathRef)makeCirclePath:(CGPoint)location radius:(CGFloat)radius
{
	
	UIBezierPath *path = [UIBezierPath bezierPath];
	[path addArcWithCenter:location
					radius:radius
				startAngle:0.0
				  endAngle:M_PI * 2.0
				 clockwise:YES];
	
	return path.CGPath;
}

-(IBAction)showMenu:(id)sender
{
	[self updateMenu];
	
	CGPoint origin = CGPointMake(CGRectGetMidX(self.menuButton.frame) - self.menu.frame.origin.x, CGRectGetMidY(self.menuButton.frame) - self.menu.frame.origin.y);
	CAShapeLayer *mask = [CAShapeLayer layer];
	mask.path = [self makeCirclePath:origin radius:0];
	mask.fillColor = [UIColor blackColor].CGColor;
	
	self.menu.layer.mask = mask;
	
	[CATransaction begin];
	CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
	animation.duration = 0.25f;
	animation.fillMode = kCAFillModeForwards;
	animation.removedOnCompletion = NO;
	
	CGPathRef newPath = [self makeCirclePath:origin radius:CGRectGetWidth(self.menu.bounds) + 20];
	
	animation.fromValue = (id)mask.path;
	animation.toValue = (__bridge id)newPath;
	
	[CATransaction setCompletionBlock:^{
		self.menu.layer.mask = nil;
	}];
	[mask addAnimation:animation forKey:@"path"];
	[CATransaction commit];
	
	self.menu.hidden = false;
	self.menuButton.hidden = true;
}

-(IBAction)hideMenu:(id)sender
{
	NSLog(@"Hide Menu");
	CGPoint origin = CGPointMake(CGRectGetMidX(self.menuButton.frame) - self.menu.frame.origin.x, CGRectGetMidY(self.menuButton.frame) - self.menu.frame.origin.y);
	CAShapeLayer *mask = [CAShapeLayer layer];
	mask.path = [self makeCirclePath:origin radius:CGRectGetWidth(self.menu.bounds) + 20];
	mask.fillColor = [UIColor blackColor].CGColor;
	
	self.menu.layer.mask = mask;
	
	[CATransaction begin];
	CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
	animation.duration = 0.25f;
	animation.fillMode = kCAFillModeForwards;
	animation.removedOnCompletion = NO;
	
	CGPathRef newPath = [self makeCirclePath:origin radius:0];
	
	animation.fromValue = (id)mask.path;
	animation.toValue = (__bridge id)newPath;
	
	[CATransaction setCompletionBlock:^{
		self.menu.hidden = true;
		self.menuButton.hidden = false;
		self.menu.layer.mask = nil;
	}];
	[mask addAnimation:animation forKey:@"path"];
	[CATransaction commit];
}

-(void)updateMenu
{
	if(self.camera.displayMarker == displaymarker_off)
	{
		if(self.switchMarkerDisplayButton.frame.size.width < 150)
		{
			[self.switchMarkerDisplayButton setTitle:@"Markers" forState:UIControlStateNormal];
		}
		else
		{
			[self.switchMarkerDisplayButton setTitle:@"Markers Hidden" forState:UIControlStateNormal];
		}
		[self.switchMarkerDisplayButton setImage:[UIImage imageNamed:@"ic_border_clear"] forState:UIControlStateNormal];
	}
	else if(self.camera.displayMarker == displaymarker_outline)
	{
		if(self.switchMarkerDisplayButton.frame.size.width < 150)
		{
			[self.switchMarkerDisplayButton setTitle:@"Markers" forState:UIControlStateNormal];
		}
		else
		{
			[self.switchMarkerDisplayButton setTitle:@"Markers Outlined" forState:UIControlStateNormal];
		}
		[self.switchMarkerDisplayButton setImage:[UIImage imageNamed: @"ic_border_outer"] forState:UIControlStateNormal];
	}
	else if(self.camera.displayMarker == displaymarker_on)
	{
		if(self.switchMarkerDisplayButton.frame.size.width < 150)
		{
			[self.switchMarkerDisplayButton setTitle:@"Markers" forState:UIControlStateNormal];
		}
		else
		{
			[self.switchMarkerDisplayButton setTitle:@"Markers Visible" forState:UIControlStateNormal];
		}
		[self.switchMarkerDisplayButton setImage:[UIImage imageNamed: @"ic_border_all"] forState:UIControlStateNormal];
	}
	else if(self.camera.displayMarker == displaymarker_debug)
	{
		if(self.switchMarkerDisplayButton.frame.size.width < 150)
		{
			[self.switchMarkerDisplayButton setTitle:@"Debug" forState:UIControlStateNormal];
		}
		else
		{
			[self.switchMarkerDisplayButton setTitle:@"Marker Debug" forState:UIControlStateNormal];
		}
		[self.switchMarkerDisplayButton setImage:[UIImage imageNamed: @"ic_border_all"] forState:UIControlStateNormal];
	}
	
	if(self.camera.cameraFeedDisplayMode == cameraDisplay_normal)
	{
		if(self.switchThresholdDisplayButton.frame.size.width < 150)
		{
			[self.switchThresholdDisplayButton setTitle:@"Display" forState:UIControlStateNormal];
		}
		else
		{
			[self.switchThresholdDisplayButton setTitle:@"Display: Normal" forState:UIControlStateNormal];
		}
		[self.switchThresholdDisplayButton setImage:[UIImage imageNamed: @"ic_filter_b_and_w_off"] forState:UIControlStateNormal];
	}
	else if(self.camera.cameraFeedDisplayMode == cameraDisplay_grey)
	{
		if(self.switchThresholdDisplayButton.frame.size.width < 150)
		{
			[self.switchThresholdDisplayButton setTitle:@"Display" forState:UIControlStateNormal];
		}
		else
		{
			[self.switchThresholdDisplayButton setTitle:@"Display: Grey" forState:UIControlStateNormal];
		}
		[self.switchThresholdDisplayButton setImage:[UIImage imageNamed: @"ic_filter_b_and_w_off"] forState:UIControlStateNormal];
	}
	else if(self.camera.cameraFeedDisplayMode == cameraDisplay_threshold)
	{
		if(self.switchThresholdDisplayButton.frame.size.width < 150)
		{
			[self.switchThresholdDisplayButton setTitle:@"Display" forState:UIControlStateNormal];
		}
		else
		{
			[self.switchThresholdDisplayButton setTitle:@"Display: Threshold" forState:UIControlStateNormal];
		}
		[self.switchThresholdDisplayButton setImage:[UIImage imageNamed: @"ic_filter_b_and_w"] forState:UIControlStateNormal];
	}
	
	// If the device doesn't have a front camera disable the camera switch button
	self.switchCameraButton.enabled = [UIImagePickerController isCameraDeviceAvailable: UIImagePickerControllerCameraDeviceFront];
	if(self.switchCameraButton.enabled)
	{
		if(self.camera.rearCamera)
		{
			if(self.switchCameraButton.frame.size.width < 150)
			{
				[self.switchCameraButton setTitle:@"Camera" forState:UIControlStateNormal];
			}
			else
			{
				[self.switchCameraButton setTitle:@"Rear Camera" forState:UIControlStateNormal];
			}
			[self.switchCameraButton setImage:[UIImage imageNamed: @"ic_camera_rear"] forState:UIControlStateNormal];
		}
		else
		{
			if(self.switchCameraButton.frame.size.width < 150)
			{
				[self.switchCameraButton setTitle:@"Camera" forState:UIControlStateNormal];
			}
			else
			{
				[self.switchCameraButton setTitle:@"Front Camera" forState:UIControlStateNormal];
			}
			[self.switchCameraButton setImage:[UIImage imageNamed: @"ic_camera_front"] forState:UIControlStateNormal];
		}
	}
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	self.camera.delegate = self;
	
	self.navigationController.navigationBarHidden = false;
	[self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
	self.navigationController.navigationBar.shadowImage = [UIImage new];
	self.navigationController.navigationBar.translucent = YES;
	self.navigationController.view.backgroundColor = [UIColor clearColor];
	self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];
	
	self.view.layer.shadowOpacity = 0.75f;
	self.view.layer.shadowRadius = 10.0f;
	self.view.layer.shadowColor = [UIColor blackColor].CGColor;
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	NSLog(@"Received memory warning");
	[self.camera stop];
}

-(UIStatusBarStyle) preferredStatusBarStyle
{
	return UIStatusBarStyleLightContent;
}

-(void) setMarkerCode:(NSString *)marker
{
	//NSLog(@"Selected setting to %@", marker);
	if(marker == nil)
	{
		if(_selected != nil)
		{
			_selected = nil;
			[self markerChanged:nil];
		}
	}
	else if(_selected == nil || ![marker isEqualToString:_selected])
	{
		_selected = marker;
		[self markerChanged:marker];
	}
}

-(void)markerChanged:(NSString *)markerCode
{
	NSLog(@"Selected set to %@", markerCode);
	if(markerCode)
	{
		if(self.delegate)
		{
			[self.delegate markerFound:markerCode];
		}
	}
}

-(void)markersFound:(NSDictionary*)markers inScene:(ACXSceneDetails *)scene
{
	if(markers.count > 0)
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.modeLabel setTextColor: [UIColor yellowColor]];
		});
	}
	else
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.modeLabel setTextColor: [UIColor whiteColor]];
		});
	}
	
	[self setMarkerCode:[self.markerSelection addMarkers:markers forExperience:self.experience.item]];
	
	NSString *helpString = [self.markerSelection getHelpString];
	if (helpString!=nil)
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.modeLabel setText:helpString];
		});
	}
	else
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.modeLabel setText:@"Place an Artcode in the viewfinder"];
		});
	}
	
	[self addMarkersToHistory:[self.markerSelection getNewlyDetectedMarkers] inScene:scene];
}

-(void)addMarkersToHistory:(NSArray*)newlyDetectedMarkers inScene:(ACXSceneDetails *)scene
{
	if (self.historyThumbnails == nil)
	{
		self.historyThumbnails = [[NSMutableArray alloc] init];//WithCapacity:maxHistory];
		self.historyThumbnailViews = [[NSMutableArray alloc] init];//WithCapacity:maxHistory];
	}
	
	if ((newlyDetectedMarkers!=nil && [newlyDetectedMarkers count]>0) || [self.historyThumbnailViews count]!=[self.markerSelection historyCount])
	{
		NSMutableArray *thumbnailViewsToReplace = [[NSMutableArray alloc] init];
		
		int width = 50;
		int height = 50;
		//int maxHistory = 5;
		CGRect parentFrame = [self.historyView frame];
		
		CGPoint origin;
		origin.x = parentFrame.size.width/2;
		origin.y = 0;
		
		float screenScale = 1;
		if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
		{
			screenScale = [[UIScreen mainScreen] scale];
		}
		NSLog(@"Screen scale: %f", screenScale);
		//screenScale*=2;
		
		// add new markers
		dispatch_async(dispatch_get_main_queue(), ^{
			// add/create new marker thumbnails
			if (newlyDetectedMarkers!=nil)
			{
				for (MarkerCode* marker in newlyDetectedMarkers)
				{
					ACXMarkerThumbnail* markerThumbnail = [[ACXMarkerThumbnail alloc] initWithContour:[[marker.markerDetails objectAtIndex:0] markerIndex] inScene:scene atWidth:width*screenScale height:height*screenScale withColor:[UIColor cyanColor]];
					[self.historyThumbnails addObject:markerThumbnail];
					
					int xStart = origin.x-(width*[self.historyThumbnailViews count])/2;
					UIImageView *thumbnailView = [[UIImageView alloc] initWithFrame:CGRectMake(xStart+width*[self.historyThumbnailViews count]+width/2, origin.y+height/2, 1, 1)];
					[thumbnailView setAlpha:0];
					[thumbnailView setImage:[markerThumbnail getUiImageWithColorCorrection:false]];
					[self.historyThumbnailViews addObject:thumbnailView];
					[self.historyView addSubview:thumbnailView];
				}
			}
			
			// mark old marker thumbnails for removal
			while ([self.historyThumbnails count] > [self.markerSelection historyCount])
			{
				[self.historyThumbnails removeObjectAtIndex:0];
				[thumbnailViewsToReplace addObject:self.historyThumbnailViews[0]];
				[self.historyThumbnailViews removeObjectAtIndex:0];
			}
			
			[UIView beginAnimations:nil context:NULL];
			// animate removal of old markers
			for (UIImageView *toRemove in thumbnailViewsToReplace)
			{
				CGRect frame = [toRemove frame];
				[toRemove setAlpha:0];
				[toRemove setFrame:CGRectMake(frame.origin.x+width/2, frame.origin.y+height/2, 0, 0)];
			}
			// animate movment of new/current marker thumbnails
			int xStart = origin.x-width*[self.historyThumbnailViews count]/2;
			for (int i=0; i<[self.historyThumbnailViews count]; ++i)
			{
				[self.historyThumbnailViews[i] setFrame:CGRectMake(xStart+i*width, origin.y, width, height)];
				[self.historyThumbnailViews[i] setAlpha:1];
				[self.historyThumbnailViews[i] setHidden:false];
			}
			[UIView setAnimationDuration:0.3];
			[UIView commitAnimations];
			
			// remove old views (after animation)
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
				for (UIImageView *toRemove in thumbnailViewsToReplace)
				{
					[toRemove removeFromSuperview];
				}
			});
		});
	}
}

@end
