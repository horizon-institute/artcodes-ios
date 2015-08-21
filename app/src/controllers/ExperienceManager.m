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
#import "Experience.h"
#import "ExperienceManager.h"
#import "JSONAPI.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GTMHTTPFetcher.h"

@interface ExperienceManager()

@property (nonatomic, retain) NSArray* experienceList;

@property (nonatomic, retain) NSMutableDictionary* experiences;
@property (nonatomic, readonly) NSString* filePath;
@property (nonatomic, readonly) NSString* defaultPath;
@property bool updated;
@property bool updating;

@end

@implementation ExperienceManager

-(instancetype)init
{
	self = [super init];
	if(self)
	{
		self.experiences = [[NSMutableDictionary alloc] init];
		self.updated = false;
		self.updating = false;
	}
	return self;
}

-(NSString*)defaultPath
{
	return [[NSBundle mainBundle] pathForResource:@"default" ofType:@"json"];
}

-(NSString*)filePath
{
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* documentsDirectory = [paths objectAtIndex:0];
	
	return [NSString stringWithFormat:@"%@/default.json", documentsDirectory];
}

-(void)save
{
	NSError* error = nil;
	NSArray* experiences = [JSONModel arrayOfDictionariesFromModels:self.experiences.allValues];
	NSData* data = [NSJSONSerialization dataWithJSONObject:experiences options:kNilOptions error:&error];
	
	if(data != nil)
	{
		NSLog(@"Saving Experiences to %@", self.filePath);
		[data writeToFile:self.filePath options:NSDataWritingAtomic error:&error];
	}
	
	if(error != nil)
	{
		NSLog(@"Error Saving: %@", error);
	}
}

-(void)load
{
	[self load:self.filePath];
}

-(void)load:(NSString*)experiencePath
{
	NSError* error = nil;
	NSData* data = [NSData dataWithContentsOfFile:experiencePath options:NSDataReadingMappedIfSafe error:&error];
	
	if(data != nil)
	{
		NSLog(@"Loading Experiences from %@", experiencePath);
		//NSLog(@"Loading Experiences: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
		NSArray* experiences = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
		if(experiences != nil && [experiences isKindOfClass:[NSArray class]])
		{
			for(NSDictionary* experienceDict in experiences)
			{
				Experience* experience = [[Experience alloc] initWithDictionary:experienceDict error:&error];
				if(error != nil)
				{
					NSLog(@"Error Loading: %@", error);
				}
				else if(experience != nil)
				{
					[self add:experience];
				}
			}
		}
		else
		{
			error = [NSError errorWithDomain:@"Experience file not dictionary" code:1 userInfo:nil];
		}
	}
	
	if(error != nil)
	{
		NSLog(@"Error Loading %@: %@", experiencePath, error);
		if(![experiencePath isEqualToString:self.defaultPath])
		{
			[self load:self.defaultPath];
		}
	}
}

-(void)loadExperience:(NSURL *)url
{
	NSLog(@"Open %@", url);
		NSData* data = [NSData dataWithContentsOfURL:url];
		NSError* error = nil;
		if(data != nil)
		{
			NSDictionary* experienceDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
			if(experienceDict != nil)
			{
				Experience* experience = [[Experience alloc] initWithDictionary:experienceDict error:&error];
				if(experience != nil)
				{
					experience.op = @"add";
					[self add:experience];
				}
			}
			
			if(error != nil)
			{
				NSLog(@"Error Loading %@: %@", url, error);
			}
		}
	
	[self update];
}

-(Experience*)getExperience:(NSString *)experienceID
{
	return [self.experiences objectForKey:experienceID];
}


-(NSArray*)experienceList
{
	if(_experienceList == nil)
	{
		NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
		
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"op != %@", @"remove"];
		NSArray* filteredExperiences = [[self.experiences allValues] filteredArrayUsingPredicate:predicate];
		self.experienceList = [filteredExperiences sortedArrayUsingDescriptors:@[sortDescriptor]];
	}
	return _experienceList;
}

-(void)update
{
	if(!self.updating)
	{
		self.updating = true;
		bool changes = false;
		NSMutableArray* experienceUpdateArray = [[NSMutableArray alloc] init];
		for(Experience* experience in self.experiences.allValues)
		{
			if(experience.op == nil || [experience.op isEqualToString:@"retrieve"])
			{
				[experienceUpdateArray addObject:@{@"id": experience.id, @"version": [NSNumber numberWithInt:experience.version]}];
			}
		}
		
		if(!changes && self.updated)
		{
			self.updating = false;
			return;
		}
		
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
		
		NSString * appBuildString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
		NSString * appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];

		NSString* version = [NSString stringWithFormat:@"%@ (%@i)", appVersionString, appBuildString];
		
		NSDictionary* experienceUpdates = @{@"experiences": experienceUpdateArray, @"version": version};
		NSError* error = nil;
		NSData* data = [NSJSONSerialization dataWithJSONObject:experienceUpdates options:kNilOptions error:&error];
		
		if(data != nil)
		{
			NSURL* url = [NSURL URLWithString:@"https://aestheticodes.appspot.com/_ah/api/experiences/v1/experiences"];
			NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60];
			[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
			request.HTTPMethod = @"PUT";
			request.HTTPBody = data;
			NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
			GTMHTTPFetcher* fetcher = [GTMHTTPFetcher fetcherWithRequest:request];
			//fetcher.authorizer = self.signIn.authentication;
			[fetcher beginFetchWithCompletionHandler:^(NSData *responseData, NSError *error)
			 {
				 if(error == nil && responseData != nil)
				 {
					 NSLog(@"Updating Experiences: %@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
					 NSDictionary* experienceUpdates = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
					 if(experienceUpdates != nil)
					 {
						 self.updated = true;
						 NSDictionary* experiences = [experienceUpdates objectForKey:@"experiences"];
						 if(experiences != nil)
						 {
							 for(NSString* experienceID in experiences.allKeys)
							 {
								 NSDictionary* experienceDict = [experiences objectForKey:experienceID];
								 if(experienceDict != nil && [experienceDict isKindOfClass:[NSDictionary class]])
								 {
									 NSString* op = [experienceDict objectForKey:@"op"];
									 if(op != nil && [op isEqualToString:@"remove"])
									 {
										 [self remove:experienceID];
									 }
									 else
									 {
										 Experience* experience = [[Experience alloc] initWithDictionary:experienceDict error:&error];
										 if(experience != nil)
										 {
											 if(experience.id != nil)
											 {
												 [self add:experience];
												 if(![experienceID isEqualToString:experience.id])
												 {
													 [self.experiences removeObjectForKey:experienceID];
												 }
											 }
										 }
									 }
								 }
								 else
								 {
									 NSLog(@"%@", experienceDict);
								 }
								 
								 if(error != nil)
								 {
									 NSLog(@"%@", error);
								 }
							 }
						 }
						 
						 for(Experience* experience in self.experiences.allValues)
						 {
							 experience.op = nil;
						 }
						 
						 [self save];
					 }
				 }
				 
				 if (error != nil)
				 {
					 NSLog(@"%@", error);
				 }
				 self.updating = false;
				 [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
			 }];
		}
		
		if(error != nil)
		{
			NSLog(@"%@", error);
		}
	}
}

-(void)remove:(NSString*) experience
{
	[self.experiences removeObjectForKey:experience];
	if(self.delegate != nil)
	{
		[self.delegate experiencesChanged];
		self.experienceList = nil;
	}
}

-(void)add:(Experience*) experience
{
	[self.experiences setObject:experience forKey:experience.id];
	if(self.delegate != nil)
	{
		[self.delegate experiencesChanged];
		self.experienceList = nil;
	}
}

@end
