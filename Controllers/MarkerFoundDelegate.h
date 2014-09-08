//
//  MarkerFoundDelegate.h
//  aestheticodes
//
//  Created by Kevin Glover on 03/07/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Experience.h"

@protocol MarkerFoundDelegate <NSObject>

-(void)markersFound:(NSDictionary*)markers;
-(void)experienceChanged:(Experience*)experience;
-(void)experiencesChanged;

@end