//
//  MarkerAction.h
//  aestheticodes
//
//  Created by Kevin Glover on 03/07/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import "JSONModel.h"
#import <Foundation/Foundation.h>

@protocol MarkerAction
@end

@interface NSDictionary (Primitive)
-(BOOL)boolForKey:(NSString*)key withDefault:(bool)value;
@end

@interface MarkerAction : JSONModel
@property (nonatomic, retain) NSString* code;
@property (nonatomic, retain) NSString* title;
@property (nonatomic, retain) NSString* description;
@property (nonatomic, retain) NSString* action;
@property (nonatomic, retain) NSString* image;
@property (nonatomic) bool editable;
@property (nonatomic) bool visible;
@property (nonatomic) bool showDetail;

-(void)load:(NSDictionary*) data;
-(NSDictionary*)toDictionary;

@end