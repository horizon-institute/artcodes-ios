//
//  ExperienceManager.m
//  aestheticodes
//
//  Created by Kevin Glover on 03/09/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import "Experience.h"
#import "ExperienceDelegate.h"
#import "ExperienceManager.h"
#import "JSONAPI.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "AuthenticationConstants.h"
#import "GTMHTTPFetcher.h"

@interface ExperienceManager()
@property (nonatomic, retain) NSMutableDictionary* experiences;
@property (nonatomic, retain) NSArray* experienceList;
@property (nonatomic, retain) GPPSignIn* signIn;
@property (nonatomic, readonly) NSString* filePath;
@property (nonatomic, readonly) NSString* defaultPath;


@end


@implementation ExperienceManager

-(instancetype)init
{
	self = [super init];
	if(self)
	{
		self.experiences = [[NSMutableDictionary alloc] init];
		_modes = @[@"detect", @"outline", @"threshold"];
		
		self.signIn = [GPPSignIn sharedInstance];
		self.signIn.shouldFetchGooglePlusUser = YES;
		self.signIn.clientID = authClientID;
		self.signIn.scopes = @[ @"https://www.googleapis.com/auth/plus.login", @"https://www.googleapis.com/auth/userinfo.email", @"email" ];
		self.signIn.keychainName = @"aestheticodes";
		
		self.signIn.delegate = self;
	}
	return self;
}

-(void)logout
{
	[self.signIn disconnect];
	[self.signIn signOut];
	[self.experiences removeAllObjects];
	NSLog(@"Logged in: %d", [self loggedIn]);
	[self load];
	[self list];
}

-(GTLPlusPerson*)getUser
{
	return self.signIn.googlePlusUser;
}

-(void)login
{
	[self.signIn authenticate];
}

-(bool)loggedIn
{
	return self.signIn.hasAuthInKeychain;
}

-(NSString*)defaultPath
{
	return [[NSBundle mainBundle] pathForResource:@"default" ofType:@"json"];
}

-(NSString*)filePath
{
	if([self loggedIn])
	{
		NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString* documentsDirectory = [paths objectAtIndex:0];
		
		return [NSString stringWithFormat:@"%@/experiences.json", documentsDirectory];
	}
	else
	{
		NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString* documentsDirectory = [paths objectAtIndex:0];
		
		return [NSString stringWithFormat:@"%@/default.json", documentsDirectory];
	}
}

-(void)save
{
	NSError* error = nil;
	NSArray* experiences = [JSONModel arrayOfDictionariesFromModels:self.experiences.allValues];
	NSDictionary* saveDict;
	if(self.selected != nil)
	{
		saveDict = @{@"experiences": experiences, @"selected": self.selected.id };
	}
	else
	{
		saveDict = @{ @"experiences":experiences };
	}
	
	NSData* data = [NSJSONSerialization dataWithJSONObject:saveDict options:kNilOptions error:&error];
	
	if(data != nil)
	{
		NSLog(@"Saving: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
		
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
		NSLog(@"Loading: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
		NSDictionary* savedExperiences = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
		if(savedExperiences != nil && [savedExperiences isKindOfClass:[NSDictionary class]])
		{
			NSString* selected = [savedExperiences objectForKey:@"selected"];
			NSArray* experiences = [savedExperiences objectForKey:@"experiences"];
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
						if(selected != nil && [selected isEqualToString:experience.id])
						{
							self.selected = experience;
						}
					}
				}
			}
			else
			{
				error = [NSError errorWithDomain:@"Experiences not found" code:1 userInfo:nil];
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
	else if(self.selected == nil)
	{
		if(self.experienceList.count > 0)
		{
			self.selected = [self.experienceList objectAtIndex:0];
		}
	}
	
}

- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth
				   error:(NSError *)error
{
	NSLog(@"Authenticated %@, with error %@", auth, error);
	if(self.delegate != nil)
	{
		[self.delegate experiencesChanged];
	}
	
	if(error != nil)
	{
		[self load];
	}
	[self list];
}

-(void)silentLogin
{
	[self load];
	if(![self.signIn trySilentAuthentication])
	{
		[self list];
	}
}

-(NSArray*)experienceList
{
	if(_experienceList == nil)
	{
		NSSortDescriptor* sortDescriptor;
		sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name"
													 ascending:YES];
		NSArray* sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
		
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"op != %@", @"remove"];
		NSArray* filteredExperiences = [[self.experiences allValues] filteredArrayUsingPredicate:predicate];
		self.experienceList = [filteredExperiences sortedArrayUsingDescriptors:sortDescriptors];
	}
	return _experienceList;
}

-(int)count
{
	return self.experienceList.count;
}

-(Experience*)getExperience:(NSIndexPath*) indexPath
{
	return [self.experienceList objectAtIndex:indexPath.row];
}

-(void)list
{
	NSMutableDictionary* versions = [[NSMutableDictionary alloc] init];
	for(Experience* experience in self.experiences.allValues)
	{
		if(experience.op == nil || [experience.op isEqualToString:@"retrieve"])
		{
			[versions setObject:[NSNumber numberWithInt:experience.version] forKey:experience.id];
		}
	}
	
	NSError* error = nil;
	NSData* data = [NSJSONSerialization dataWithJSONObject:versions options:kNilOptions error:&error];
	
	if(data != nil)
	{
		NSURL* url = [NSURL URLWithString:aesListURL];
		NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60];
		[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
		request.HTTPMethod = @"PUT";
		request.HTTPBody = data;
		NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
		GTMHTTPFetcher* fetcher = [GTMHTTPFetcher fetcherWithRequest:request];
		fetcher.authorizer = self.signIn.authentication;
		[fetcher beginFetchWithCompletionHandler:^(NSData *responseData, NSError *error)
		 {
			 if(error == nil && responseData != nil)
			 {
				 NSLog(@"Experience List: %@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
				 NSDictionary* experienceList = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
				 if(experienceList != nil)
				 {
					 NSArray* experiences = [experienceList objectForKey:@"experiences"];
					 if(experiences != nil)
					 {
						 for(NSDictionary* experienceDict in experiences)
						 {
							 if([experienceDict isKindOfClass:[NSDictionary class]])
							 {
								 NSString* op = [experienceDict objectForKey:@"op"];
								 if(op != nil && [op isEqualToString:@"remove"])
								 {
									 [self remove:[experienceDict objectForKey:@"id"]];
								 }
								 else
								 {
									 Experience* experience = [[Experience alloc] initWithDictionary:experienceDict error:&error];
									 if(experience != nil)
									 {
										 if(experience.id != nil)
										 {
											 [self add:experience];
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
						 
						 [self save];
					 }
				 }
			 }
			 
			 if (error != nil)
			 {
				 NSLog(@"%@", error);
			 }
		 }];
	}
	
	if(error != nil)
	{
		NSLog(@"%@", error);
	}
}


-(void)update
{
	NSMutableArray* experienceUpdateArray = [[NSMutableArray alloc] init];
	for(Experience* experience in self.experiences.allValues)
	{
		if(experience.op != nil && ![experience.op isEqualToString:@"retrieve"])
		{
			if([self loggedIn])
			{
				if([@"remove" isEqualToString:experience.op])
				{
					[experienceUpdateArray addObject:@{@"id": experience.id, @"op": @"remove"}];
				}
				else
				{
					[experienceUpdateArray addObject:[experience toDictionary]];
				}
			}
		}
	}
	
	if(experienceUpdateArray.count == 0)
	{
		return;
	}
	
	NSDictionary* experienceUpdates = @{@"experiences": experienceUpdateArray};
	NSError* error = nil;
	NSData* data = [NSJSONSerialization dataWithJSONObject:experienceUpdates options:kNilOptions error:&error];
	
	if(data != nil)
	{
		NSURL* url = [NSURL URLWithString:aesUpdateURL];
		NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60];
		[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
		request.HTTPMethod = @"PUT";
		request.HTTPBody = data;
		NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
		GTMHTTPFetcher* fetcher = [GTMHTTPFetcher fetcherWithRequest:request];
		fetcher.authorizer = self.signIn.authentication;
		[fetcher beginFetchWithCompletionHandler:^(NSData *responseData, NSError *error)
		 {
			 if(error == nil && responseData != nil)
			 {
				 NSLog(@"Experience Updates: %@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
				 NSDictionary* experienceUpdates = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
				 if(experienceUpdates != nil)
				 {
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
												 if(self.selected != nil && [experienceID isEqualToString:experienceID])
												 {
													 self.selected = experience;
												 }
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
						 
						 [self save];
					 }
				 }
			 }
			 
			 if (error != nil)
			 {
				 NSLog(@"%@", error);
			 }
		 }];
	}
	
	if(error != nil)
	{
		NSLog(@"%@", error);
	}
}

-(void)remove:(NSString*) experience
{
	[self.experiences removeObjectForKey:experience];
	if(self.selected != nil && [self.selected.id isEqualToString:experience])
	{
		if(self.experiences.count > 0)
		{
			NSSortDescriptor* sortDescriptor;
			sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name"
														 ascending:YES];
			NSArray* sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
			NSArray* experienceList = [[self.experiences allValues] sortedArrayUsingDescriptors:sortDescriptors];
			
			self.selected = [experienceList objectAtIndex:0];
		}
		else
		{
			self.selected = nil;
		}
	}
	
	if(self.delegate != nil)
	{
		[self.delegate experiencesChanged];
		self.experienceList = nil;
	}
}

-(void)setSelected:(Experience *)experience
{
	_selected = experience;
	if(self.delegate != nil)
	{
		[self.delegate experienceChanged:experience];
	}
	[self save];
}

-(void)add:(Experience*) experience
{
	[self.experiences setObject:experience forKey:experience.id];
	if(self.selected != nil && [self.selected.id isEqualToString:experience.id])
	{
		_selected = experience;
	}
	
	if(self.delegate != nil)
	{
		[self.delegate experiencesChanged];
		self.experienceList = nil;
	}
}

-(void)setMode:(NSString *)newMode
{
	if(![newMode isEqualToString:self.mode])
	{
		_mode = newMode;
		if(self.delegate != nil)
		{
			[self.delegate modeChanged:newMode];
		}
	}
}

@end