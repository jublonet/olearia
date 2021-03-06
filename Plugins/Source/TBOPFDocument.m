//
//  BBSTBOPFDocument.m
//  TalkingBook Framework
//
//  Created by Kieren Eaton on 15/04/08.
//  Copyright 2008 BrainBender Software. All rights reserved.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "TBOPFDocument.h"

@interface TBOPFDocument ()

- (NSArray *)processSpineSection:(NSXMLElement *)aRootElement;
- (NSArray *)processTourSection:(NSXMLElement *)aRootElement;
- (NSDictionary *)processManifestSection:(NSXMLElement *)aRootElement;
- (NSDictionary *)processGuideSection:(NSXMLElement *)aRootElement;

- (NSInteger)prevSpinePos;
- (NSInteger)nextSpinePos;
- (NSString *)filenameForCurrentSpinePos;
- (NSString *)filenameForID:(NSString *)anID;

@end



@implementation TBOPFDocument

- (id) init
{
	if (!(self=[super init])) return nil;
		
	return self;
}

- (void)processData
{
		
		manifest = [NSDictionary dictionaryWithDictionary:[self processManifestSection:[xmlPackageDoc rootElement]]];
		spine = [NSArray arrayWithArray:[self processSpineSection:[xmlPackageDoc rootElement]]];
		guide = [NSDictionary dictionaryWithDictionary:[self processGuideSection:[xmlPackageDoc rootElement]]];
		currentPosInSpine = -1;
		
		// set the book title
		NSString *titleStr = [self stringForXquery:@"dc-metadata/data(*:Title)" ofNode:[self metadataNode]];
		bookData.bookTitle = (titleStr) ? titleStr : LocalizedStringInTBStdPluginBundle(@"No Title", @"no title string"); 
		
		// set the subject
		NSString *subjectStr = [self stringForXquery:@"dc-metadata/data(*:Subject)" ofNode:[self metadataNode]];
		bookData.bookSubject =  (subjectStr) ? subjectStr : LocalizedStringInTBStdPluginBundle(@"No Subject", @"no subject string");
		
}



- (void) dealloc
{	
	// cleanup nice
	// check what we may have used
	
	[spine release];
	[manifest release];
	[guide release];
	[tour release];
	
	[super dealloc];
}

- (NSString *)mediaFormatString
{
	return [self stringForXquery:@"//meta[@name][ends-with(@name,'multimediaType')]/data(@content)" 
						  ofNode:[xmlPackageDoc rootElement]];
}


#pragma mark -
#pragma mark Private Methods

- (NSInteger)prevSpinePos
{
	return ((currentPosInSpine - 1) < 0) ?  0 : (currentPosInSpine - 1);
	
}

- (NSInteger)nextSpinePos
{
	NSUInteger newPos = (currentPosInSpine + 1);
	return (newPos == [spine count]) ? [spine count] : newPos;
	
}

- (NSString *)nextSpineID
{
	NSInteger newPos = [self nextSpinePos];
	if(newPos == currentPosInSpine)
		return nil; // we are at the end of the spine
	
	currentPosInSpine = newPos;
	return [spine objectAtIndex:currentPosInSpine];
}

- (NSString *)prevSpineID
{ 
	NSInteger newPos = [self prevSpinePos];
	if(newPos == currentPosInSpine)
		return nil; // we are at the beginning of the spine
	
	currentPosInSpine = newPos;
	return [spine objectAtIndex:currentPosInSpine];
}

#pragma mark -
#pragma mark Public Accessors

- (NSString *)nextAudioSegmentFilename
{
	//NSString *spineId;
	// first get the ID reference from the spine
	// check if we are at the first element of the spine
	NSInteger newPos = [self nextSpinePos];
	if(newPos > currentPosInSpine)
	{	
		currentPosInSpine = newPos;
		//spineId = [NSString stringWithString:[spine objectAtIndex:currentPosInSpine]];
	
		// check if we got an ID ref back
		//if(spineId != nil)
		//{
			// return the filename from the manifest
			return [self filenameForCurrentSpinePos];
		//}

	}
	
	return nil;

}

- (NSString *)prevAudioSegmentFilename
{
	//NSString *spineId;
	// first get the ID reference from the spine

	NSInteger newPos = [self prevSpinePos];
	if(newPos < currentPosInSpine)
	{	
		currentPosInSpine = newPos;
		//spineId = [NSString stringWithString:[spine objectAtIndex:currentPosInSpine]];
	
		// check if we got an 
		//if(spineId != nil)
		//{
			// return the filename from the manifest
			return [self filenameForCurrentSpinePos];
		//}
		
	
	}
	
	return nil;
}


// get the filename for an associated id from the manifest
- (NSString *)filenameForID:(NSString *)anID
{
	return [[manifest objectForKey:anID] objectForKey:@"href"];
}

- (NSString *)filenameForCurrentSpinePos
{
	// a nil value indicates there was no id or filename
	return [self filenameForID:[spine objectAtIndex:currentPosInSpine]];
}

#pragma mark -
#pragma mark Private Methods
		
- (NSArray *)processSpineSection:(NSXMLElement *)aRootElement
{
	NSMutableArray * spineContents = [[[NSMutableArray alloc] init] autorelease];
	
	NSArray *spineNodes = [aRootElement nodesForXPath:@"spine" error:nil];
	// check if there is a spine node
	if ([spineNodes count] == 1)
	{
		NSArray *spineElements = [[spineNodes objectAtIndex:0] nodesForXPath:@"itemref" error:nil];
		// check if there are some itemref nodes
		if ([spineElements count] > 0)
		{
			for(NSXMLElement *anElement in spineElements)
			{
				// get the element contained in the node then add its string contents to the temp array
				[spineContents addObject:[[[anElement attributes] objectAtIndex:0] stringValue]];
			}
		}
	}
		
	// return the array which may be nil if there was no spine 
	return ([spineContents count]) ? spineContents : nil; 
	
}

- (NSDictionary *)processManifestSection:(NSXMLElement *)aRootElement
{
	NSMutableDictionary * manifestContents = [[[NSMutableDictionary alloc] init] autorelease];
	
	NSArray *manifestNodes = [aRootElement nodesForXPath:@"manifest" error:nil];
	// check if there is a manifest node - there will be only one
	if([manifestNodes count] == 1)
	{
		NSArray *manifestElements = [[manifestNodes objectAtIndex:0] nodesForXPath:@"item" error:nil];
		// check if there are item nodes
		if ([manifestElements count] > 0)
		{
			for(NSXMLElement *anElement in manifestElements)
			{
				// get the values and keys and add them tou our dictionary 
				NSMutableDictionary *nodeContents = [[[NSMutableDictionary alloc] init] autorelease];
				[nodeContents setValue:[[anElement attributeForName:@"href"] stringValue] forKey:@"href"];
				[nodeContents setValue:[[anElement attributeForName:@"media-type"] stringValue] forKey:@"media-type"];
				[manifestContents setObject:(NSDictionary *)nodeContents forKey:[[anElement attributeForName:@"id"] stringValue]];
			}
		}
	}
	// return the dict which may be nil if there was no manifest 
	return ([manifestContents count]) ? manifestContents : nil;
}


- (NSDictionary *)processGuideSection:(NSXMLElement *)aRootElement
{
	NSMutableDictionary *guideContents = [[[NSMutableDictionary alloc] init] autorelease];

	NSArray *guideNodes = [aRootElement nodesForXPath:@"guide" error:nil];
	// check if there is a manifest node - there will be only one
	if([guideNodes count] == 1)
	{
		NSArray *guideElements = [[guideNodes objectAtIndex:0] nodesForXPath:@"reference" error:nil];
		// check if there are item nodes
		if ([guideElements count] > 0)
		{
			for(NSXMLElement *anElement in guideElements)
			{

				NSDictionary *nodeContents = [[[NSDictionary alloc] initWithObjectsAndKeys:
											  [[anElement attributeForName:@"type"] stringValue], @"type",
											  [[anElement attributeForName:@"href"] stringValue], @"href",
											   nil] autorelease];
				[guideContents setObject:(NSDictionary *)nodeContents forKey:[[anElement attributeForName:@"title"] stringValue]];
			}
		}
	}
	return ([guideContents count]) ? guideContents : nil;
}

- (NSArray *)processTourSection:(NSXMLElement *)aRootElement
{
	
	NSMutableArray *tourContents = [[[NSMutableArray alloc] init] autorelease];
	
	return ([tourContents count]) ? tourContents : nil;
}

@synthesize spine,manifest,tour,guide;

@synthesize currentPosInSpine;






@end

