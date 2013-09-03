//
//  ACMarkerDb.m
//  aestheticodes
//
//  Created by horizon on 30/08/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import "ACMarkerDB.h"
#import "ACConstants.h"

@implementation ACMarkerDB

static ACMarkerDB *sharedInstance;


-(id)init
{
    self = [super init];
    if (self){
        
    }
    return self;
}

+(id)getSharedInstance
{
    if (sharedInstance == nil)
        sharedInstance = [[ACMarkerDB alloc] init];
    return sharedInstance;
}

-(NSString*)getUrlStringForMarker:(DtouchMarker*)marker
{
    NSString *markerCodeKey = [marker codeKey];
    NSString *markerURL = nil;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if ([markerCodeKey caseInsensitiveCompare:Code1] == NSOrderedSame)
    {
        markerURL = [userDefaults objectForKey:Code1];
    }
    
    if ([markerCodeKey caseInsensitiveCompare:Code2] == NSOrderedSame)
    {
        markerURL = [userDefaults objectForKey:Code2];
    }
    
    if ([markerCodeKey caseInsensitiveCompare:Code3] == NSOrderedSame)
    {
        markerURL = [userDefaults objectForKey:Code3];
    }
    
    if ([markerCodeKey caseInsensitiveCompare:Code4] == NSOrderedSame)
    {
        markerURL = [userDefaults objectForKey:Code4];
    }
    
    if ([markerCodeKey caseInsensitiveCompare:Code5] == NSOrderedSame)
    {
        markerURL = [userDefaults objectForKey:Code5];
    }
    
    return markerURL;
}

@end
