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

#import "ACXGreyscaleViewController.h"
#import "ACXGreyscaler.h"
#import "ACODESMachineSettings.h"
#import "MarkerCamera.h"

NSString *const COLOUR_FILTER_NAME_KEY = @"name";
NSString *const COLOUR_FILTER_SHORT_NAME_KEY = @"shortName";
NSString *const COLOUR_FILTER_VALUES_KEY = @"values";
NSArray	 *const COLOUR_FILTER_PRESETS = @[
	@{COLOUR_FILTER_NAME_KEY:@"Intensity (default)",	COLOUR_FILTER_SHORT_NAME_KEY:@"I",	COLOUR_FILTER_VALUES_KEY: @[@"RGB",@(0.299),@(0.587),@(0.114)]},
	@{COLOUR_FILTER_NAME_KEY:@"Red in RGB",				COLOUR_FILTER_SHORT_NAME_KEY:@"R",	COLOUR_FILTER_VALUES_KEY: @[@"RGB",@(1),@(0),@(0)]},
	@{COLOUR_FILTER_NAME_KEY:@"Green in RGB",			COLOUR_FILTER_SHORT_NAME_KEY:@"G",	COLOUR_FILTER_VALUES_KEY: @[@"RGB",@(0),@(1),@(0)]},
	@{COLOUR_FILTER_NAME_KEY:@"Blue in RGB",			COLOUR_FILTER_SHORT_NAME_KEY:@"B",	COLOUR_FILTER_VALUES_KEY: @[@"RGB",@(0),@(0),@(1)]},
	@{COLOUR_FILTER_NAME_KEY:@"Mean", COLOUR_FILTER_SHORT_NAME_KEY:@"x",	COLOUR_FILTER_VALUES_KEY: @[@"RGB",@(0.3333),@(0.3334),@(0.3333)]},
	@{COLOUR_FILTER_NAME_KEY:@"Cyan in CMYK",			COLOUR_FILTER_SHORT_NAME_KEY:@"Ck",	COLOUR_FILTER_VALUES_KEY: @[@"CMYK",@(1),@(0),@(0),@(0)]},
	@{COLOUR_FILTER_NAME_KEY:@"Magenta in CMYK",		COLOUR_FILTER_SHORT_NAME_KEY:@"Mk",	COLOUR_FILTER_VALUES_KEY: @[@"CMYK",@(0),@(1),@(0),@(0)]},
	@{COLOUR_FILTER_NAME_KEY:@"Yellow in CMYK",			COLOUR_FILTER_SHORT_NAME_KEY:@"Yk",	COLOUR_FILTER_VALUES_KEY: @[@"CMYK",@(0),@(0),@(1),@(0)]},
	@{COLOUR_FILTER_NAME_KEY:@"Black in CMYK",			COLOUR_FILTER_SHORT_NAME_KEY:@"Kk",	COLOUR_FILTER_VALUES_KEY: @[@"CMYK",@(0),@(0),@(0),@(1)]},
	@{COLOUR_FILTER_NAME_KEY:@"Cyan in CMY",			COLOUR_FILTER_SHORT_NAME_KEY:@"C",	COLOUR_FILTER_VALUES_KEY: @[@"CMY",@(1),@(0),@(0)]},
	@{COLOUR_FILTER_NAME_KEY:@"Magenta in CMY",			COLOUR_FILTER_SHORT_NAME_KEY:@"M",	COLOUR_FILTER_VALUES_KEY: @[@"CMY",@(0),@(1),@(0)]},
	@{COLOUR_FILTER_NAME_KEY:@"Yellow in CMY",			COLOUR_FILTER_SHORT_NAME_KEY:@"Y",	COLOUR_FILTER_VALUES_KEY: @[@"CMY",@(0),@(0),@(1)]},
];


@interface ACXGreyscaleViewController ()
@property (nonatomic, retain) CvVideoCamera* videoCamera;
@property ACXGreyscaler* greyscaler;
@property bool hasChanged;
@property NSMutableArray *colourFilterOptions;
@end


@implementation ACXGreyscaleViewController

+(NSString*)getColourFilterPresetNameForValues:(NSArray*)values
{
	if (values==nil)
	{
		return COLOUR_FILTER_PRESETS[0][COLOUR_FILTER_NAME_KEY];
	}
	
	for (NSDictionary *colourFilterDetails in COLOUR_FILTER_PRESETS)
	{
		NSArray *value = colourFilterDetails[COLOUR_FILTER_VALUES_KEY];
		if ([value isEqualToArray:values])
		{
			return colourFilterDetails[COLOUR_FILTER_NAME_KEY];
		}
	}
	
	return @"Other";
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	self.greyscaler = [self.experience getImageGreyscaler];
	
	// setup the switch/slider
	self.invertSwitch.on = self.experience.invertGreyscale;
	self.hueSlider.value = self.experience.hueShift;
	
	// setup the colour filter picker
	self.colourFilterOptions = [COLOUR_FILTER_PRESETS mutableCopy];
	[self.colourPreset removeAllSegments];
	bool filterFound = false;
	NSString *nameKey = [self.colourFilterOptions count]>5?COLOUR_FILTER_SHORT_NAME_KEY:COLOUR_FILTER_NAME_KEY;
	for (int i=0; i<[self.colourFilterOptions count]; ++i)
	{
		NSDictionary *colourFilterDetails = self.colourFilterOptions[i];
		[self.colourPreset insertSegmentWithTitle:colourFilterDetails[nameKey] atIndex:i animated:NO];
		NSArray *value = colourFilterDetails[COLOUR_FILTER_VALUES_KEY];
		if ([self.experience.greyscaleOptions isEqualToArray:value])
		{
			[self.colourPreset setSelectedSegmentIndex:i];
			filterFound = true;
		}
		// if the experience contains something that is not a preset add it as an "other" option:
		if (i==[self.colourFilterOptions count]-1 && !filterFound)
		{
			filterFound = true;
			if (self.experience.greyscaleOptions==nil)
			{
				[self.colourPreset setSelectedSegmentIndex:0];
			}
			else
			{
				[self.colourFilterOptions addObject:@{COLOUR_FILTER_NAME_KEY:@"Other", COLOUR_FILTER_SHORT_NAME_KEY:@"?", COLOUR_FILTER_VALUES_KEY: self.experience.greyscaleOptions}];
			}
		}
	}
	
	self.hasChanged = true;
	// Ask the system to notify us when in forground: (removed in [self viewDidDisappear])
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(start)
												 name:UIApplicationWillEnterForegroundNotification
											   object:nil];
	[self start];
}

- (IBAction)invertSwitchChanged:(id)sender
{
	self.experience.invertGreyscale = self.invertSwitch.on;
	self.hasChanged = true;
}
- (IBAction)colourPresetChanged:(id)sender
{
	self.experience.greyscaleOptions = self.colourFilterOptions[[self.colourPreset selectedSegmentIndex]][COLOUR_FILTER_VALUES_KEY];
	self.hasChanged = true;
}
- (IBAction)hueSliderChanged:(id)sender
{
	self.experience.hueShift = self.hueSlider.value;
	self.hasChanged = true;
}

-(void)viewDidDisappear:(BOOL)animated
{
	// Remove the forground notification.
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
	
	[self stop];
	[super viewDidDisappear:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[self stop];
}

- (void) start
{
	// Create OpenCV camera object:
	if (self.videoCamera == NULL)
	{
		self.videoCamera = [[CvVideoCameraMod alloc] initWithParentView:self.cameraImageView];
		self.videoCamera.delegate = self;
		
		self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
		self.videoCamera.grayscaleMode = NO;
		self.videoCamera.rotateVideo = false;
		
		[self.videoCamera unlockFocus];
	}
	
	// Set camera settings:
	ACODESMachineSettings* machineSettings = [ACODESMachineSettings getMachineSettings];
	
	self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
	ACODESCameraSettings *cameraSettings = [machineSettings getRearCameraSettings];
	
	
	if (cameraSettings)
	{
		self.videoCamera.defaultAVCaptureSessionPreset = [cameraSettings getAVCaptureSessionPreset];
		self.videoCamera.defaultFPS = [cameraSettings getDefaultFPS];
	}
	else
	{
		NSLog(@"Using default (low) settings");
		self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
		self.videoCamera.defaultFPS = 10;
	}
	
	[self.videoCamera start];
}

- (void) stop
{
	if(self.videoCamera.running)
	{
		[self.videoCamera stop];
	}
}


#pragma mark - Protocol CvVideoCameraDelegate
- (void)processImage:(cv::Mat&)screenImage
{
	[self.videoCamera updateOrientation];
	
	// if the settings have changed get a new greyscaler object
	if (self.hasChanged)
	{
		self.hasChanged = false;
		self.greyscaler = [self.experience getImageGreyscaler];
		
		// update labels:
		[self.colourPresetLabel performSelectorOnMainThread:@selector(setText:) withObject:[NSString stringWithFormat:@"Greyscale Filter: %@", self.colourFilterOptions[[self.colourPreset selectedSegmentIndex]][COLOUR_FILTER_NAME_KEY]] waitUntilDone:false];
		[self.hueShiftLabel performSelectorOnMainThread:@selector(setText:) withObject:[NSString stringWithFormat:@"Hue Shift: %d/180%@", (int) self.experience.hueShift, self.experience.hueShift==0?@" (off)":@""] waitUntilDone:false];
	}
	
	// apply to image:
	cv::Mat greyscaleBuffer(screenImage.size(), CV_8UC1);
	[self.greyscaler greyscaleImage:screenImage to:greyscaleBuffer];
	cv::cvtColor(greyscaleBuffer, screenImage, CV_GRAY2BGRA);
}

@end
