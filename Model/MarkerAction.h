//
//  MarkerAction.h
//  aestheticodes
//
//  Created by Kevin Glover on 03/07/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (Primitive)
-(BOOL)boolForKey:(NSString*)key withDefault:(bool)value;
@end

@interface MarkerAction : NSObject
@property NSString* code;
@property NSString* title;
@property NSString* description;
@property NSString* action;
@property NSString* image;
@property bool editable;
@property bool visible;
@property bool showDetail;

-(void)load:(NSDictionary*) data;
-(NSDictionary*)toDictionary;
@end

