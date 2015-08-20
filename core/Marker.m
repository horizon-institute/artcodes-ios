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
#import "Marker.h"

@implementation NSDictionary (Primitive)

-(NSString*)stringForKey:(NSString*)key withDefault:(NSString*)value
{
	NSString* string = self[key];
	if(string != nil)
	{
		return string;
	}
	return value;
}

-(BOOL)boolForKey:(NSString*)key withDefault:(bool)value
{
	NSNumber* number = self[key];
	if(number != nil)
	{
		return [number boolValue];
	}
	return value;
}

@end

@implementation Marker

@synthesize description;

-(instancetype)init
{
	self = [super init];
	if(self)
	{
		self.showDetail = false;
		self.resetHistoryOnOpen = true;
		self.changeToExperienceWithIdOnOpen = nil;
	}
	return self;
}

-(NSDictionary*)toDictionary
{
	NSMutableDictionary* result = [[NSMutableDictionary alloc] init];
	
	[result setValue:self.code forKey:@"code"];
	[result setValue:self.title forKey:@"title"];
	[result setValue:self.description forKey:@"description"];
	[result setValue:self.action forKey:@"action"];
	[result setValue:self.image forKey:@"image"];
	
	[result setValue:[NSNumber numberWithBool:self.showDetail] forKey:@"showDetail"];
	[result setValue:[NSNumber numberWithBool:self.resetHistoryOnOpen] forKey:@"resetHistoryOnOpen"];
	
	[result setValue:self.changeToExperienceWithIdOnOpen forKey:@"changeToExperienceWithIdOnOpen"];
	
	return result;
}

+(BOOL)propertyIsOptional:(NSString*)propertyName
{
	return YES;
}

-(void)load:(NSDictionary *)data
{
	self.code = data[@"code"];
	self.title = [data valueForKey:@"title"];
	self.description = [data valueForKey:@"description"];
	self.action = [data valueForKey:@"action"];
	self.image = [data valueForKey:@"image"];

	self.showDetail	= [data boolForKey:@"showDetail" withDefault:true];
	self.resetHistoryOnOpen	= [data boolForKey:@"resetHistoryOnOpen" withDefault:true];
	
	self.changeToExperienceWithIdOnOpen = [data valueForKey:@"changeToExperienceWithIdOnOpen"];
}

@end
