//
//  ExperienceManager.h
//  aestheticodes
//
//  Created by Kevin Glover on 03/09/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Experience.h"
#import "MarkerFoundDelegate.h"

@interface ExperienceManager : NSObject
@property (nonatomic, retain) NSMutableArray* experiences;
@property (nonatomic, retain) Experience* selected;
@property (nonatomic, weak) id<MarkerFoundDelegate> delegate;

-(void)load;
+(void)save:(Experience*) experience;
@end