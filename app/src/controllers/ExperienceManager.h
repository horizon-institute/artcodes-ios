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
#import "GPPSignIn.h"

@protocol ExperienceDelegate <NSObject>

-(void)experiencesChanged;

@end


@interface ExperienceManager : NSObject<GPPSignInDelegate>
@property (nonatomic, weak) id<ExperienceDelegate> delegate;
@property (nonatomic, retain) NSArray* experienceList;

-(void)load;
-(void)update;
-(void)save;
-(void)login;
-(void)silentLogin;
-(void)logout;
-(bool)loggedIn;
-(GTLPlusPerson*)getUser;
-(void)add:(Experience*) experience;
-(Experience*)getExperience:(NSString*) id;
@end