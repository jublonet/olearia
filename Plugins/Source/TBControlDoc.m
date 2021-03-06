//
//  TBControlDoc.m
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 14/08/08.
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

#import "TBControlDoc.h"

@interface TBControlDoc ()

@property (readwrite, copy)	NSURL	*fileURL;

@end




@implementation TBControlDoc

- (id)init
{
	if (!(self=[super init])) return nil;
	
	bookData = [TBBookData sharedBookData];
	self.currentNavPoint = nil;
	self.currentPositionID = @"";
	self.fileURL = nil;
	
	
	
	return self;
}


- (void) dealloc
{
	[currentPositionID release];
	self.currentNavPoint = nil;
	[fileURL release];
	bookData = nil;

	[super dealloc];
}


#pragma mark -
#pragma mark methods that may be overridden By Subclasses

- (BOOL)openWithContentsOfURL:(NSURL *)aURL
{
	BOOL loadedOk = NO;
	
	NSError *theError = nil;
	
	self.currentNavPoint = nil;
	self.fileURL = nil;
	
	xmlControlDoc = [[[NSXMLDocument alloc] initWithContentsOfURL:aURL options:NSXMLDocumentTidyXML error:&theError] retain];
	
	if((xmlControlDoc) && (!theError))
	{	
		loadedOk = YES;
		self.fileURL = [aURL copy];
	}
	else
	{
		NSAlert *theAlert = [NSAlert alertWithError:theError];
		[theAlert setMessageText:LocalizedStringInTBStdPluginBundle(@"Error Opening Control File", @"control open fail alert short msg")];
		[theAlert setInformativeText:LocalizedStringInTBStdPluginBundle(@"Failed to open the control file.\n Playback and limited navigation may be possible if the OPF file loaded correctly.", @"control open fail alert long msg")];
		[theAlert beginSheetModalForWindow:[NSApp keyWindow] 
							 modalDelegate:nil 
							didEndSelector:nil 
							   contextInfo:nil];
	}

	return loadedOk;
}

- (void)processData
{
#ifdef DEBUG
	NSLog(@"superclass method of %@ used",[self className]);
#endif
	[self doesNotRecognizeSelector:_cmd];
}

- (NSString *)mediaFormatString
{
#ifdef DEBUG
	NSLog(@"superclass method of %@ used",[self className]);
#endif
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (NSXMLNode *)metadataNode
{

	return nil;
}

- (void)jumpToNodeWithPath:(NSString *)fullPathToNode
{
#ifdef DEBUG
	NSLog(@"superclass method of %@ used",[self className]);
#endif
	[self doesNotRecognizeSelector:_cmd];
}

- (void)jumpToNodeWithIdTag:(NSString *)anIdTag
{
#ifdef DEBUG
	NSLog(@"superclass method of %@ used",[self className]);
#endif
	[self doesNotRecognizeSelector:_cmd];
}

- (BOOL)moveToNextSegment
{
#ifdef DEBUG
	NSLog(@"superclass method of %@ used",[self className]);
#endif
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}

- (void)moveToNextSegmentAtSameLevel
{
#ifdef DEBUG
	NSLog(@"superclass method of %@ used",[self className]);
#endif
	[self doesNotRecognizeSelector:_cmd];
}

- (void)moveToPreviousSegment
{
#ifdef DEBUG
	NSLog(@"superclass method of %@ used",[self className]);
#endif
	[self doesNotRecognizeSelector:_cmd];
}

- (NSString *)filenameFromID:(NSString *)anIdString
{
	NSAssert(anIdString != nil, @"anIdString is nil");
	NSInteger markerPos = [anIdString rangeOfString:@"#"].location;
	return (markerPos > 0) ? [anIdString substringToIndex:markerPos] : anIdString;
	
}

- (NSString *)currentIdTag
{
#ifdef DEBUG
	NSLog(@"Superclass method 'referenceTagForCurrentPosition' of %@ used",[self className]);
#endif
	[self doesNotRecognizeSelector: _cmd];
	return nil;
}


- (NSString *)contentFilenameFromCurrentNode
{
#ifdef DEBUG
	NSLog(@"Superclass method 'filenameFromCurrentNode' of %@ used",[self className]);
#endif
	[self doesNotRecognizeSelector: _cmd];
	return nil;
}

- (void)updateDataForCurrentPosition
{
#ifdef DEBUG
	NSLog(@"superclass method of %@ used",[self className]);
#endif
	[self doesNotRecognizeSelector:_cmd];
}

- (BOOL)canGoNext
{
#ifdef DEBUG
	NSLog(@"superclass method of %@ used",[self className]);
#endif
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}
- (BOOL)canGoPrev;
{
#ifdef DEBUG
	NSLog(@"superclass method of %@ used",[self className]);
#endif
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}

- (BOOL)canGoUpLevel;
{
#ifdef DEBUG
	NSLog(@"superclass method of %@ used",[self className]);
#endif
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}

- (BOOL)canGoDownLevel;
{
#ifdef DEBUG
	NSLog(@"superclass method of %@ used",[self className]);
#endif
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}

- (void)goUpALevel;
{
#ifdef DEBUG
	NSLog(@"superclass method of %@ used",[self className]);
#endif
	[self doesNotRecognizeSelector:_cmd];
	
}

- (void)goDownALevel;
{
#ifdef DEBUG
	NSLog(@"superclass method of %@ used",[self className]);
#endif
	[self doesNotRecognizeSelector:_cmd];
	
}

- (BOOL)nextSegmentIsAvailable
{
#ifdef DEBUG
	NSLog(@"superclass method of %@ used",[self className]);
#endif
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}

- (BOOL)PreviousSegmentIsAvailable
{
#ifdef DEBUG
	NSLog(@"superclass method of %@ used",[self className]);
#endif
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}

- (NSString *)stringForXquery:(NSString *)aQuery ofNode:(NSXMLNode *)theNode
{
	NSArray *queryContents = nil;
	// if we pass in nil for the node we use the root node as a default 
	if(!theNode)
		queryContents = [[xmlControlDoc rootElement] objectsForXQuery:aQuery error:nil];
	else	
		queryContents = [theNode objectsForXQuery:aQuery error:nil];
	
	return ([queryContents count] > 0) ? [queryContents objectAtIndex:0] : nil;
}




#pragma mark -
#pragma mark ===== Notification Methods =====

- (void)doPositionalUpdate:(NSNotification *)aNote
{
	NSLog(@"idtag = %@",(NSString*)[aNote object]);

}

@synthesize currentNavPoint;
@synthesize currentPositionID;
@synthesize navigateForChapters;
@synthesize fileURL;

@end
