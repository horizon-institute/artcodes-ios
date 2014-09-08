//
//  MarkerAction.m
//  aestheticodes
//
//  Created by Kevin Glover on 03/07/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//
#import "MarkerAction.h"

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

@implementation MarkerAction

@synthesize description;

-(instancetype)init
{
	self = [super init];
	if(self)
	{
		self.editable = true;
		self.visible = true;
		self.showDetail = true;
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
	
	[result setValue:[NSNumber numberWithBool:self.editable] forKey:@"editable"];
	[result setValue:[NSNumber numberWithBool:self.visible] forKey:@"visible"];
	[result setValue:[NSNumber numberWithBool:self.showDetail] forKey:@"showDetail"];
	
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
	
	self.editable = [data boolForKey:@"editable" withDefault:true];
	self.visible = [data boolForKey:@"visible" withDefault:true];
	self.showDetail	= [data boolForKey:@"showDetail" withDefault:true];
}

@end
