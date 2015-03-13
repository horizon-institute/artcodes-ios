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
#import "Experience.h"
#import "ExperienceController.h"
#import "JSONAPI.h"

@interface ExperienceController()

@property (nonatomic, retain) NSMutableArray* listeners;

@end

@implementation ExperienceController

-(instancetype)init
{
	self = [super init];
	if(self)
	{
		self.item = [[Experience alloc] init];
		self.listeners = [[NSMutableArray alloc] init];
	}
	return self;
}


-(void)setItem:(Experience *)experience
{
	NSLog(@"Set experience %@", experience.name);
	_item = experience;
	for (id<ExperienceControllerDelegate> listener in self.listeners)
	{
		NSLog(@"Fire listener");
		[listener experienceChanged:experience];
	}
}

-(void)addListener:(id<ExperienceControllerDelegate>)listener
{
	NSLog(@"Listener added");
	[self.listeners addObject:listener];
}

-(void)removeListener:(id<ExperienceControllerDelegate>)listener
{
	[self.listeners removeObject:listener];
}

@end