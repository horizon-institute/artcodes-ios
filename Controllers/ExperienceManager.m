//
//  ExperienceManager.m
//  aestheticodes
//
//  Created by Kevin Glover on 03/09/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import "MarkerFoundDelegate.h"
#import "Experience.h"
#import "ExperienceManager.h"
#import "JSONAPI.h"

@implementation ExperienceManager

-(instancetype)init
{
	self = [super init];
	if(self)
	{
		self.experiences = [[NSMutableArray alloc] init];
	}
	return self;
}

+(void)save:(Experience*)experience
{
	NSString* json = [experience toJSONString];
	NSLog(@"Saving Experience %@", json);
	NSData* data = [json dataUsingEncoding:NSUTF8StringEncoding];
	
	NSString* filePath = [[NSBundle mainBundle] pathForResource:experience.id ofType:@"json"];
	[data writeToFile:filePath atomically:YES];
	
	experience.changed = false;
}


-(void)load
{
	NSLog(@"Loading Experiences");
	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"experiences" ofType:@"json"];
	NSData *data = [NSData dataWithContentsOfFile:filePath];
	NSError* error;
	// do stuff
	if(data != nil)
	{
		NSArray* experiences = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
		if(experiences != nil)
		{
			for(NSString* experienceID in experiences)
			{
				NSLog(@"Loading Experience %@", experienceID);
				NSString* experiencePath = [[NSBundle mainBundle] pathForResource:experienceID ofType:@"json"];
				NSData *data = [NSData dataWithContentsOfFile:experiencePath];

				if(data != nil)
				{
					Experience* experience = [[Experience alloc] initWithData:data error:&error];
					if(experience != nil)
					{
						[self add:experience];
					}
					else if(error != nil)
					{
						NSLog(@"%@", error);
					}
				}
				else if(error != nil)
				{
					NSLog(@"%@", error);
				}
			}
		}
		else if(error != nil)
		{
			NSLog(@"%@", error);
		}
	}
	else if(error != nil)
	{
		NSLog(@"%@", error);
	}
	
	if(self.delegate != nil)
	{
		[self.delegate experiencesChanged];
	}
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSMutableDictionary* experienceURLs = [[NSMutableDictionary alloc] init];
		for(Experience* experience in self.experiences)
		{
			[experienceURLs setValue:experience.updateURL forKey:experience.id];
		}
	
		NSURL* url = [NSURL URLWithString:@"http://www.wornchaos.org/experiences/experiences.json"];
		NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60];
		NSLog(@"Finding remote experiences");
		
		NSURLResponse* response = nil;
		NSError* error = nil;
		NSData * data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
		
		if(data != nil)
		{
			NSLog(@"Remote experiences found: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
			NSDictionary* newURLs = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
			if(newURLs != nil)
			{
				[experienceURLs addEntriesFromDictionary:newURLs];
			}
			else if(error != nil)
			{
				NSLog(@"%@", error);
			}
		}
		else if(error != nil)
		{
			NSLog(@"%@", error);
		}
		
		for(NSString* experienceID in experienceURLs)
		{
			NSURL* experienceURL = [NSURL URLWithString:[experienceURLs valueForKey:experienceID]];
			NSLog(@"Opening experience %@", [experienceURL absoluteString]);
			request = [NSMutableURLRequest requestWithURL:experienceURL];
			
			for(Experience* existingExperience in self.experiences)
			{
				if(existingExperience.lastUpdate != nil && [existingExperience.id isEqualToString:experienceID])
				{
					[request setValue:@"Your string" forHTTPHeaderField:@"If-Modified-Since"];
					break;
				}
			}
			
			NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
			if(data != nil)
			{
				Experience* experience = [[Experience alloc] initWithData:data error:&error];
				
				if(experience != nil)
				{
					if(response != nil)
					{
						experience.lastUpdate = [NSString stringWithFormat:@"%@", [[(NSHTTPURLResponse *)response allHeaderFields] objectForKey:@"Last-Modified"]];
					}
					[ExperienceManager save:experience];
					
					dispatch_async(dispatch_get_main_queue(), ^{
						[self add:experience];
					});
				}
				else if(error != nil)
				{
					NSLog(@"%@", error);
				}
			}
			else if(error != nil)
			{
				NSLog(@"%@", error);
			}
		}
		
		NSMutableArray* experienceIDs = [[NSMutableArray alloc] init];
		for(Experience* experience in self.experiences)
		{
			[experienceIDs addObject:experience.id];
		}
		
		data = [NSJSONSerialization dataWithJSONObject:experienceIDs options:kNilOptions error:&error];
		if(data != nil)
		{
			[data writeToFile:filePath atomically:false];
		}
		else if(error != nil)
		{
			NSLog(@"%@", error);
		}
	});
}

-(void)add:(Experience*) experience
{
	for(Experience* existingExperience in self.experiences)
	{
		if([experience.id isEqualToString:existingExperience.id])
		{
			[self.experiences removeObject:existingExperience];
			break;
		}
	}
	
	[self.experiences addObject:experience];
	NSLog(@"%lu experiences", [self.experiences count]);
	if(self.selected == nil || [self.selected.id isEqualToString:experience.id])
	{
		self.selected = experience;
		if(self.delegate != nil)
		{
			[self.delegate experienceChanged:experience];
		}
	}
	
	if(self.delegate != nil)
	{
		[self.delegate experiencesChanged];
	}
}

@end