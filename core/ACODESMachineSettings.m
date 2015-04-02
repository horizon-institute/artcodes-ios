/*
 * Aestheticodes recognises a different marker scheme that allows the
 * creation of aesthetically pleasing, even beautiful, codes.
 * Copyright (C) 2015  Aestheticodes
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
    NSString *localSettingsFilePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory,@"artcodeHardwareSettings.json"];
    bool localSettingsFileExists = [[NSFileManager defaultManager] fileExistsAtPath:localSettingsFilePath];
    
    ACODESMachineSettings* machineSettings = [[ACODESMachineSettings alloc] init];
    bool successfullyParsed = false;
    if (localSettingsFileExists)
    {
		NSLog(@"Loading local machine settings file %@", localSettingsFilePath);
        NSData *data = [NSData dataWithContentsOfFile:localSettingsFilePath];
		if(data != nil)
		{
			successfullyParsed = [machineSettings loadSettingsData: data];
		}
    }
    
    if (!localSettingsFileExists || !successfullyParsed)
    {
        // else load the settings file from the bundle
        NSString *bundleSettingsFilePath = [[NSBundle mainBundle] pathForResource:@"artcodeHardwareSettings" ofType:@"json"];
        NSLog(@"Loading bundle machine settings file %@", bundleSettingsFilePath);
		NSData *data = [NSData dataWithContentsOfFile:bundleSettingsFilePath];
        [machineSettings loadSettingsData: data];
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
                                              if (urlData && [[ACODESMachineSettings getMachineSettings] loadSettingsData:urlData])
                                              {
                                                  NSLog(@"Saving downloaded machine settings file.");
                                                  [urlData writeToFile:localSettingsFilePath atomically:YES];
                                                  //[[ACODESMachineSettings getMachineSettings] loadSettingsData:urlData];
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


