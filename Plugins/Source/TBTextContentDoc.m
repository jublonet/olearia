//
//  TBTextContentDoc.m
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 13/07/09.
//  Copyright 2009 BrainBender Software. All rights reserved.
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

#import "TBTextContentDoc.h"

@interface TBTextContentDoc ()



@end

@interface TBTextContentDoc (Private)

- (NSUInteger)itemsOnCurrentLevel;
- (NSUInteger)itemIndexOnCurrentLevel;
- (void)updateInfoWithInterveningNodes;
- (BOOL)isHeadingNode:(NSXMLNode *)aNode;

@end


@implementation TBTextContentDoc

- (id)init
{
	if (!(self=[super init])) return nil;
	
	bookData = [TBBookData sharedBookData];
	
	return self;
}

- (BOOL)openWithContentsOfURL:(NSURL *)aURL
{
	BOOL loadedOk = NO;
	NSError *theError = nil;
	
	_xmlTextDoc = [[NSXMLDocument alloc] initWithContentsOfURL:aURL options:NSXMLDocumentTidyXML error:&theError];
	
	if(_xmlTextDoc)
	{	
		
		_currentNode = nil;
		_currentNode = [[_xmlTextDoc nodesForXPath:@"/dtbook[1]/book[1]/bodymatter[1]" error:nil] objectAtIndex:0];
		
		
		if(nil != _currentNode)
		{	
			[self updateInfoWithInterveningNodes];
			loadedOk = YES;
			
		}
	}
	else // we got a nil return so display the error to the user
	{
		NSAlert *theAlert = [NSAlert alertWithError:theError];
		[theAlert setMessageText:NSLocalizedString(@"Error Opening Text Content", @"text content open fail alert short msg")];
		[theAlert setInformativeText:NSLocalizedString(@"There was a problem opening the textual content file (.xml).\n This book may still play if it has audio content.", @"text content open fail alert long msg")];
		[theAlert beginSheetModalForWindow:[NSApp keyWindow] 
									modalDelegate:nil 
								  didEndSelector:nil 
									  contextInfo:nil];
	}
	
	return loadedOk;
}

- (void)processData
{
	
	[self updateInfoWithInterveningNodes];
	
}

- (void)jumpToNodeWithIdTag:(NSString *)aTag
{
	if(aTag)
	{	
		NSString *queryStr = [NSString stringWithFormat:@"/dtbook[1]/book[1]//*[@id='%@']",aTag];
		NSArray *tagNodes = nil;
		tagNodes = [_xmlTextDoc nodesForXPath:queryStr error:nil];
		
		_currentNode = ([tagNodes count]) ? [tagNodes objectAtIndex:0] : _currentNode;
	}
}



@end

@implementation TBTextContentDoc (Synchronization)

- (void)jumpToNodeWithPath:(NSString *)fullPathToNode
{
	NSArray *nodes = nil;
	if(nil != fullPathToNode)
		nodes = [_xmlTextDoc nodesForXPath:fullPathToNode error:nil];
	_currentNode = ([nodes count] > 0) ? [nodes objectAtIndex:0] : _currentNode;
}

- (void)jumpToNodeWithIdTag:(NSString *)anIdTag
{
	
}

- (void)updateDataForCurrentPosition
{
	
}

- (NSString *)currentIdTag
{
	
	//NSArray *idTags = nil;
	NSString *aTag = nil;
	aTag = [[(NSXMLElement *)_currentNode attributeForName:@"id"] stringValue];
	//idTags = [_currentNode objectsForXQuery:@"./data(@id)" error:nil];
	
	return aTag;
	//return ([idTags count]) ? [idTags objectAtIndex:0] : nil;
}

@end


@implementation TBTextContentDoc (Navigation)

- (void)moveToNextSegment
{
//	NSXMLNode *newNode = nil;
//	newNode = [_currentNode 
	
//	if(YES == [self canGoDownLevel]) // first check if we can go down a level
//	{	
//		
//		_currentNode = [[_currentNode nextNode] nextNode]; // get first node after the "level?" node
//		bookData.currentLevel++; // increment the level
//	}
//	else if(YES == [self canGoNext]) // we then check if there is another navPoint at the same level
//		_currentNode = [_currentNode nextSibling];
//	else if(YES == [self canGoUpLevel]) // we have reached the end of the current level so go up
//	{
//		if(nil != [[_currentNode parent] nextSibling]) // check that there is something after the parent to play
//		{	
//			// get the parent then its sibling as we have already played 
//			// the parent before dropping into this level
//			_currentNode = [[_currentNode parent] nextSibling];
//			bookData.currentLevel--; // decrement the current level
//		}
//	}

	[self updateInfoWithInterveningNodes];
	
}

- (void)moveToNextSegmentAtSameLevel
{
	// this only used when the user chooses to go to the next file on a given level
//	currentNavPoint = [currentNavPoint nextSibling];
//	[self updateDataForCurrentPosition];
}

- (void)moveToPreviousSegment
{
	
//		BOOL foundNode = NO;
//	
//	if(NO == navigateForChapters)
//	{
//		// we have a node on this level
//		currentNavPoint = [currentNavPoint previousSibling];
//	}
//	else
//	{
//		// we only make it here if we are travelling backwards across segments
//		
//		// reset the flag
//		navigateForChapters = NO;
//		
//		// look back through the previous nodes for a navpoint
//		while(NO == foundNode)
//		{
//			currentNavPoint = [currentNavPoint previousNode];
//			if([[currentNavPoint name] isEqualToString:@"navPoint"])
//				foundNode = YES;
//		}
//		
//		
//		//self.bookData.currentLevel = [self levelOfNode:_currentNavPoint];
//		
//		
//		
//		
//	}
//	
//	//self.bookData.sectionTitle = [self stringForXquery:@"navLabel/data(text)" ofNode:_currentNavPoint];
//
//	[self updateDataForCurrentPosition];
	
}

- (void)goUpALevel
{
	
}

- (void)goDownALevel
{
	
	 
}

@end


@implementation TBTextContentDoc (Information)

- (BOOL)canGoNext
{
	// return YES if we can go forward in the navmap
	return ([self itemIndexOnCurrentLevel] < ([self itemsOnCurrentLevel] - 1)) ? YES : NO; 
}

- (BOOL)canGoPrev
{
	// return YES if we can go backwards
	return ([self itemIndexOnCurrentLevel] > 0) ? YES : NO;
}

- (BOOL)canGoUpLevel
{
	// return Yes if we are at a lower level
	return (bookData.currentLevel > 1) ? YES : NO;
}

- (BOOL)canGoDownLevel
{
	// return YES if there is level? node as the next node
	NSString *newLevelString = [NSString stringWithFormat:@"level%d",bookData.currentLevel+1];
	return ([[[_currentNode nextNode] name] isEqualToString:newLevelString]);
}


- (NSString *)contentText
{
	
	return [_currentNode stringValue];
}

@end

@implementation TBTextContentDoc (Private)

- (NSUInteger)itemsOnCurrentLevel
{
	return [[_currentNode parent] childCount]; 
}

- (NSUInteger)itemIndexOnCurrentLevel
{
	// returns an index of the current node relative to the other nodes on the same level
	return [_currentNode index];
}


- (void)updateInfoWithInterveningNodes
{
	while(![[_currentNode name] isEqualToString:@"sent"])
	{
		if([[_currentNode name] hasPrefix:@"level"])
			bookData.currentLevel = [[[_currentNode name] substringFromIndex:4] integerValue];
		else if([[_currentNode name] isEqualToString:@"pagenum"])
			bookData.currentPage = [[_currentNode stringValue] integerValue];
		else if([self isHeadingNode:_currentNode])
			bookData.sectionTitle = [_currentNode stringValue];
		
		_currentNode = [_currentNode nextNode];
	}
	
}

- (BOOL)isHeadingNode:(NSXMLNode *)aNode
{
	NSString *nodeName = [aNode name];
	if([nodeName length] >= 2)
	{
		unichar checkChar =  [nodeName characterAtIndex:0];
		unichar levelChar =  [nodeName characterAtIndex:1];
		
		// check if we have a 'h' as the first character which denotes a level header AND the second character is a digit
		return (('h' == checkChar) && (isdigit(levelChar))) ? YES : NO; 

	}
	
	return NO;
}

@end


