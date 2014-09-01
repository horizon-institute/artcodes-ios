//
//  ACODESMachineSettings.h
//  aestheticodes
//
//  Created by Will on 29/08/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACODESCameraSettings.h"

@interface ACODESMachineSettings : NSObject

+(ACODESMachineSettings*)getMachineSettings;
+(ACODESMachineSettings*)loadSettings;

+(NSString*) machineName;
+(bool)regexTestWithModelPattern:(NSString*)modelRegex;
+(bool)regexTestWithOsPattern:(NSString*)osRegex;

@property (nonatomic, retain) NSString* updateURL;
@property (nonatomic, retain) NSString* deviceName;
@property (nonatomic, retain) ACODESCameraSettings* rearCameraSettings;
@property (nonatomic, retain) ACODESCameraSettings* frontCameraSettings;

-(bool)loadSettingsData:(NSData*) data;

-(NSString*)getUpdateURL;
-(NSString*)getDisplayName;
-(ACODESCameraSettings*)getRearCameraSettings;
-(ACODESCameraSettings*)getFrontCameraSettings;

@end
