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