//
//  ExperienceManager.h
//  aestheticodes
//
//  Created by Kevin Glover on 03/09/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Experience.h"
#import "ExperienceDelegate.h"
#import "GPPSignIn.h"

@interface ExperienceManager : NSObject<GPPSignInDelegate>
@property (nonatomic, retain) Experience* selected;
@property (nonatomic, retain, readonly) NSArray* modes;
@property (nonatomic, retain) NSString* mode;
@property (nonatomic, weak) id<ExperienceDelegate> delegate;
@property (nonatomic) int count;

-(void)load;
-(void)update;
-(void)save;
-(void)login;
-(void)silentLogin;
-(void)logout;
-(bool)loggedIn;
-(GTLPlusPerson*)getUser;
-(void)add:(Experience*) experience;
-(Experience*)getExperience:(NSIndexPath*) indexPath;
@end