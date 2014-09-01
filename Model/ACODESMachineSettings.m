//
//  ACODESMachineSettings.m
//  aestheticodes
//
//  Created by Will on 29/08/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACODESMachineSettings.h"
#import <sys/utsname.h>

@implementation ACODESMachineSettings

static ACODESMachineSettings *machineSettings = nil;
+ (ACODESMachineSettings*)getMachineSettings
{
    @synchronized(self)
	{
        if (machineSettings == nil)
		{
            machineSettings = [ACODESMachineSettings loadSettings];
		}
    }
    return machineSettings;
}

+(ACODESMachineSettings*)loadSettings
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *localSettingsFilePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory,@"acodes_ios_machine_settings.json"];
    bool localSettingsFileExists = [[NSFileManager defaultManager] fileExistsAtPath:localSettingsFilePath];
    
    ACODESMachineSettings* machineSettings = [[ACODESMachineSettings alloc] init];
    bool successfullyParsed = false;
    if (localSettingsFileExists)
    {
        NSLog(@"Loading local machine settings file");
        // if we have a previously downloaded settings file use that
        NSData *data = [NSData dataWithContentsOfFile:localSettingsFilePath];
        successfullyParsed = [machineSettings loadSettingsData: data];
    }
    
    if (!localSettingsFileExists || !successfullyParsed)
    {
        NSLog(@"Loading bundle machine settings file");
        // else load the settings file from the bundle
        NSString *bundleSettingsFilePath = [[NSBundle mainBundle] pathForResource:@"acodes_ios_machine_settings" ofType:@"json"];
        NSData *data = [NSData dataWithContentsOfFile:bundleSettingsFilePath];
        successfullyParsed = [machineSettings loadSettingsData: data];
    }
    
    
    // download new settings file that can be used on next app start
    NSURL *URL = [NSURL URLWithString:[machineSettings getUpdateURL]];
    if ([machineSettings getUpdateURL]!=nil &&
        ![[machineSettings getUpdateURL] isEqualToString:@""] &&
        URL)
    {
        NSLog(@"Loading machine settings URL %@",[machineSettings getUpdateURL]);
        NSURLRequest *request = [NSURLRequest requestWithURL:URL];
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                                completionHandler:
                                      ^(NSData *urlData, NSURLResponse *response, NSError *error) {
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              if (urlData)
                                              {
                                                  NSLog(@"Saving downloaded machine settings file.");
                                                  [urlData writeToFile:localSettingsFilePath atomically:YES];
                                                  [[ACODESMachineSettings getMachineSettings] loadSettingsData:urlData];
                                              }
                                          });
                                      }];
        [task resume];
    }
    
	return machineSettings;
}

-(bool)loadSettingsData:(NSData*) data
{
	NSError* jsonError;
	NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];

    if (! json)
	{
		NSLog(@"Got an error parsing machine settings json: %@", jsonError);
        return false;
	}
	else
	{
        self.updateURL = [json valueForKey:@"updateUrl"];
        
        NSArray* deviceList = [json valueForKey:@"devices"];
        for(NSDictionary* device in deviceList)
        {
            NSLog(@"Checking machine settings for: %@", [device valueForKey:@"displayName"]);
            if ([ACODESMachineSettings regexTestWithModelPattern:[device valueForKey:@"machineNamePattern"]] && [ACODESMachineSettings regexTestWithOsPattern:[device valueForKey:@"osVersionPattern"]])
            {
                self.deviceName = [device valueForKey:@"displayName"];
                NSLog(@"Loading machine settings for: %@", self.deviceName);
                
                NSDictionary* rearCamera = [device valueForKey:@"backCamera"];
                if (rearCamera)
                {
                    self.rearCameraSettings = [[ACODESCameraSettings alloc] init];
                    [self.rearCameraSettings loadSettingsData:rearCamera];
                }
                else
                {
                    self.rearCameraSettings = nil;
                }
                
                
                NSDictionary* frontCamera = [device valueForKey:@"frontCamera"];
                if (frontCamera)
                {
                    self.frontCameraSettings = [[ACODESCameraSettings alloc] init];
                    [self.frontCameraSettings loadSettingsData:frontCamera];
                }
                else
                {
                    self.frontCameraSettings = nil;
                }
                
                break;
            }
            
        }
	}
    return true;
}

-(NSString*)getDisplayName
{
    return self.deviceName;
}
-(NSString*)getUpdateURL
{
    return self.updateURL;
}
-(ACODESCameraSettings*)getRearCameraSettings
{
    return self.rearCameraSettings;
}
-(ACODESCameraSettings*)getFrontCameraSettings
{
    return self.frontCameraSettings;
}

+(NSString*) machineName
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

+ (bool)regexTestWithModelPattern:(NSString*)modelRegex;
{
    return [[NSPredicate predicateWithFormat:@"SELF MATCHES %@", modelRegex] evaluateWithObject:[ACODESMachineSettings machineName]];
}

+ (bool)regexTestWithOsPattern:(NSString*)osRegex;
{
    return [[NSPredicate predicateWithFormat:@"SELF MATCHES %@", osRegex] evaluateWithObject:[[UIDevice currentDevice] systemVersion]];
}

@end


