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
#import "MarkerSelection.h"
#import "MarkerCode.h"
#import "Experience.h"

@interface MarkerSelection ()
@property (nonatomic, retain) NSMutableDictionary *occurrences;
@property (nonatomic, retain) NSMutableArray *history;
@property int required;
@property (nonatomic, retain) NSDate* lastAddedToHistory;

@property (nonatomic, retain) NSMutableArray *justAddedToHistory;


@property (nonatomic, retain) NSMutableArray *inMiddleOfDetectingTheseMarkers;
@property (nonatomic, retain) NSString *mostRecentDetection;

@end

@implementation MarkerSelection

-(id)init{
	self = [super init];
	if (self)
	{
		self.occurrences = [[NSMutableDictionary alloc] init];
		self.required = 5;
		
		self.history = [[NSMutableArray alloc] init];
		self.justAddedToHistory = [[NSMutableArray alloc] init];
		
		self.inMiddleOfDetectingTheseMarkers = [[NSMutableArray alloc] init];
	}
	return self;
}

/**
 * Returns the marker code with the highest number of occurrences past the required ammount.
 * If an experience is provided searches for group/sequential marker codes from the experience,
 * and prioritises marker codes in the experience over other codes.
 */
-(NSString*)addMarkers:(NSDictionary*)markers forExperience:(Experience*)experience
{
	NSDate* time = [NSDate date];
	
	// Add given markers to the data structure
	for (NSString* markerCode in markers)
	{
		MarkerCode* marker = [markers objectForKey:markerCode];
		long occurence = marker.occurrence;
		MarkerCode *existingMarker = [self.occurrences objectForKey:markerCode];
		if (existingMarker != nil)
		{
			if (existingMarker.occurrence < self.required && existingMarker.occurrence + occurence >= self.required)
			{
				// add to history
				if ([self.history count]==0 || [[NSDate date] timeIntervalSinceDate:self.lastAddedToHistory]>=1 || ![existingMarker.codeKey isEqualToString:self.history[[self.history count]-1]])
				{
					[self.history addObject:existingMarker.codeKey];
					[self.justAddedToHistory addObject:marker];
					self.lastAddedToHistory = time;
					existingMarker.firstDetected = time;
				}
			}
			
			// Existing marker found: increase its occurence count
			existingMarker.occurrence = existingMarker.occurrence + occurence;
			existingMarker.lastDetected = time;
		}
		else
		{
			// New marker has been found: add to data structure
			marker.occurrence = occurence;
			//[marker.nodeIndexes removeAllObjects];
			[self.occurrences setObject:marker forKey:markerCode];
			[self.inMiddleOfDetectingTheseMarkers addObject:markerCode];
		}
	}
	
	
	// Find markers that have the required occurrences to be detected and remove those that have timed out
	NSMutableArray* toRemove = [[NSMutableArray alloc] init];
	NSMutableArray* detected = [[NSMutableArray alloc] init];
	for(NSString* markerCode in self.occurrences)
	{
		MarkerCode* marker = [self.occurrences objectForKey:markerCode];
		if([markers objectForKey:markerCode]==nil)
		{
			marker.occurrence = MIN(self.required * 5, marker.occurrence-1);
			if (marker.occurrence <= 0)
			{
				[toRemove addObject:markerCode];
				[self.inMiddleOfDetectingTheseMarkers removeObject:markerCode];
				continue;
			}
		}
		
		if (marker.occurrence >= self.required)
		{
			[detected addObject:markerCode];
			[self.inMiddleOfDetectingTheseMarkers removeObject:markerCode];
		}
	}
	[self.occurrences removeObjectsForKeys:toRemove];
	
	self.mostRecentDetection = [self getMarkersFromDetected:detected justAddedToHistory:self.justAddedToHistory inExperience:experience];
	
	return self.mostRecentDetection;
}

-(NSString*)getMarkersFromDetected:(NSArray*)detected justAddedToHistory:(NSMutableArray*)justAddedToHistory inExperience:(Experience*)experience
{
	NSString* result = [MarkerSelection getGroupMarkerFromDetected:detected occurrences:self.occurrences inExperience:experience];
	if (result==nil)
	{
		result = [MarkerSelection getSequentialMarkerFromHistory:self.history justAddedToHistory:justAddedToHistory inExperience:experience];
		if (result==nil)
		{
			result = [MarkerSelection getStandardMarkerFromDetected:detected occurrences:self.occurrences inExperience:experience];
		}
	}
	else
	{
		// prune history anyway:
		[MarkerSelection getSequentialMarkerFromHistory:self.history justAddedToHistory:justAddedToHistory inExperience:experience];
	}
	return result;
}

+(NSString*)getGroupMarkerFromDetected:(NSArray*)detected occurrences:(NSMutableDictionary*)occurrences inExperience:(Experience*)experience
{
	// search for group actions in markers detected (longest codes first, excludes single codes)
	if ([detected count]>1 && experience!=nil)
	{
		NSMutableArray* combinations = [[NSMutableArray alloc] init];
		[MarkerSelection combinationsOf:detected withMaxSize:(int)[detected count] result:combinations];
		for (int i=(int)[combinations count]-1; i>=1; --i)
		{
			NSArray* mostRecentGroup = nil;
			NSString* mostRecentGroupStr = nil;
			for (NSArray* code in combinations[i])
			{
				NSString* joinedCodeString = [code componentsJoinedByString:@"+"];
				if ([experience getMarker:joinedCodeString]!=nil &&
					[MarkerSelection markerDetectionTimesOverlapInCodes:code occurrences:occurrences] &&
					[[MarkerSelection getMostRecentDetectionTime:code excluding:mostRecentGroup occurrences:occurrences] compare:[MarkerSelection getMostRecentDetectionTime:mostRecentGroup excluding:code occurrences:occurrences]]==NSOrderedDescending)
				{
					mostRecentGroup = code;
					mostRecentGroupStr = joinedCodeString;
				}
			}
			
			if (mostRecentGroupStr!=nil)
			{
				return mostRecentGroupStr;
			}
		}
	}
	return nil;
}

+(NSString*)getSequentialMarkerFromHistory:(NSMutableArray*)history justAddedToHistory:(NSMutableArray*)justAddedToHistory inExperience:(Experience*)experience
{
	// search for sequential actions in markers detected history (longest codes first, excludes single codes)
	if ([history count]>0  && experience!=nil)
	{
		bool foundPrefix = false;
		int start=0;
		while (start<[history count])
		{
			NSArray* subCode = [history subarrayWithRange:NSMakeRange(start, [history count]-start)];
			NSString* joinedCodeString = [subCode componentsJoinedByString:@">"];
			if ([experience getMarker:joinedCodeString] && [subCode count]>1)
			{
				// a sequential marker was found
				return joinedCodeString;
			}
			else if (!foundPrefix && ![experience hasCodeBeginningWith:[NSString stringWithFormat:@"%@>",joinedCodeString]])
			{
				// no seqential marker starting with joinedCodeString was found so remove the first part of it from history
				if ([justAddedToHistory count]==[history count])
				{
					[justAddedToHistory removeObjectAtIndex:0];
				}
				[history removeObjectAtIndex:0];
				start = 0;
			}
			else
			{
				// either a seqential marker starts with joinedCodeString or a previous joinedCodeString
				foundPrefix = true;
				start++;
			}
		}
	}
	return nil;
}

+(NSString*)getStandardMarkerFromDetected:(NSArray*)detected occurrences:(NSMutableDictionary*)occurrences inExperience:(Experience*)experience
{
	MarkerCode* result = nil;
	bool resultIsInExperience = false;
	for (NSString* code in detected)
	{
		MarkerCode* marker = occurrences[code];
		bool markerIsInExperience = experience==nil || [experience getMarker:code]!=nil;
		if (result==nil || (!resultIsInExperience && markerIsInExperience) || (resultIsInExperience==markerIsInExperience && marker.occurrence>result.occurrence))
		{
			result = marker;
			resultIsInExperience = markerIsInExperience;
		}
	}
	
	return result==nil ? nil : result.codeKey;
}


/**
 * Get all the combinations of objects upto a maximum size for the combination and add it to the result NSMutableArray.
 * E.g. [combinationsOf:[1,2,3] withMaxSize:2 result:[]] changes the result array to [([1],[2],[3]),([1,2],[1,3],[2,3])] where () denotes an NSSet and [] denotes an NSArray.
 */
+(void)combinationsOf:(NSArray*)objects withMaxSize:(int)n result:(NSMutableArray*)result
{
	if (n==1)
	{
		// the result for this case is all the objects in indivisual arrays
		NSMutableSet* resultForN = [[NSMutableSet alloc] init];
		for (NSString* code in objects)
		{
			[resultForN addObject:@[code]];
		}
		[result addObject:resultForN];
	}
	else if (n==[objects count])
	{
		// the result for this case is a sorted list of the input (+ n-1)
		[self combinationsOf:objects withMaxSize:n-1 result:result];
		NSMutableSet* resultForN = [[NSMutableSet alloc] init];
		[resultForN addObject:[objects sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
			return [a compare:b];
		}]];
		[result addObject:resultForN];
	}
	else
	{
		NSMutableSet* resultForN = [[NSMutableSet alloc] init];
		[self combinationsOf:objects withMaxSize:n-1 result:result];
		NSSet* resultForNMinus1 = result[[result count]-1];
		
		for (NSString* code in objects)
		{
			for (NSArray* setMinus1 in resultForNMinus1)
			{
				if (![setMinus1 containsObject:code])
				{
					NSMutableArray* aResult = [[NSMutableArray alloc] initWithArray:setMinus1];
					[aResult addObject:code];
					[resultForN addObject:[aResult sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
						return [a compare:b];
					}]];
				}
			}
		}
		
		[result addObject:resultForN];
	}
}


+(NSDate*)getMostRecentDetectionTime:(NSArray*)codes excluding:(NSArray*)excluding occurrences:(NSDictionary*)occurrences
{
	NSDate* mostRecentTime = [[NSDate alloc] initWithTimeIntervalSince1970:0];
	if (codes!=nil)
	{
		for (NSString* codeStr in codes)
		{
			if (excluding == nil || ![excluding containsObject:codeStr])
			{
				MarkerCode* code = occurrences[codeStr];
				if (code != nil && [code.lastDetected compare:mostRecentTime]==NSOrderedDescending)
				{
					mostRecentTime = code.lastDetected;
				}
			}
		}
	}
	return mostRecentTime;
}

+(bool)markerDetectionTimesOverlapInCodes:(NSArray*)codes occurrences:(NSDictionary*)occurrences
{
	for (int i=0; i<[codes count]-1; ++i)
	{
		MarkerCode* code1 = occurrences[(NSString*) codes[i]];
		bool overlapFound = false;
		for (int j=i+1; j<[codes count]; ++j)
		{
			MarkerCode* code2 = occurrences[codes[j]];
			overlapFound = [MarkerSelection doTimesOverlapFirstDetected1:code1.firstDetected lastDetected1:code1.lastDetected firstDetected2:code2.firstDetected lastDetected2:code2.lastDetected];
			if (overlapFound)
			{
				break;
			}
		}
		if (!overlapFound)
		{
			return false;
		}
	}
	return true;
}

+(bool)doTimesOverlapFirstDetected1:(NSDate*)firstDetected1 lastDetected1:(NSDate*)lastDetected1 firstDetected2:(NSDate*)firstDetected2 lastDetected2:(NSDate*)lastDetected2
{
	return ([firstDetected1 compare:lastDetected2]==NSOrderedAscending)  &&  ([lastDetected1 compare:firstDetected2]==NSOrderedDescending);
}


-(void)resetAndResetHistory:(bool)resetHistory
{
	NSLog(@"Reset Selection");
	[self.occurrences removeAllObjects];
	if (resetHistory)
	{
		[self.history removeAllObjects];
	}
}

-(NSArray*)getNewlyDetectedMarkers
{
	NSArray *result = [[NSArray alloc] initWithArray:self.justAddedToHistory];
	[self.justAddedToHistory removeAllObjects];
	return result;
}

-(int)historyCount
{
	return (int) [self.history count];
}

-(NSString*)getHelpStringForExperience:(Experience*)experience
{
	if ([self.inMiddleOfDetectingTheseMarkers count] > 0)
	{
		return @"Hold it there!";
	}
	if ([self.history count] > 0)
	{
		if (self.mostRecentDetection != nil && [self.mostRecentDetection rangeOfString:@">"].location != NSNotFound)
		{
			return @"Found a sequence!";
		}
		else
		{
			if (experience!=nil && experience.hintText!=nil && experience.hintText[@"sequencePart"]!=nil)
			{
				return experience.hintText[@"sequencePart"];
			}
			else
			{
				return @"The code you just read is part of a sequence, find the next one!";
			}
		}
	}
	if ([self.occurrences count] > 0)
	{
		if (self.mostRecentDetection != nil && [self.mostRecentDetection rangeOfString:@"+"].location != NSNotFound)
		{
			return @"Found a group!";
		}
		else
		{
			return @"Found one!";
		}
	}
	
	return nil;
}

@end