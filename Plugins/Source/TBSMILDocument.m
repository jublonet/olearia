//
//  BBSTBSMILDocument.m
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

#import "TBSMILDocument.h"
#import <QTKit/QTKit.h>
#import "NSString-TBAdditions.h"

@interface TBSMILDocument ()

@property (readwrite, retain)   NSXMLNode			*_currentNode;
@property (readwrite, retain)	NSXMLDocument		*_xmlSmilDoc;
@property (readwrite, copy)		NSURL				*_currentFileURL;

- (void)resetSmil;

@end

@interface TBSMILDocument (Private)

- (NSString *)idTagFromSrcString:(NSString *)anIdString;
- (NSString *)filenameFromCompoundString:(NSString *)aString;
- (BOOL)isCompoundString:(NSString *)aString;

@end


@implementation TBSMILDocument


- (id) init
{
	if (!(self=[super init])) return nil;
	
	_currentFileURL = [[NSURL alloc] init];
	_currentNode = [[NSXMLNode alloc] init];
	currentNodePath = [[NSString alloc] init];
	
	return self;
}

- (void) dealloc
{
	[_currentFileURL release];
	_currentFileURL = nil;
	
	[_xmlSmilDoc release];
	_xmlSmilDoc = nil;
	
	_currentNode = nil;
	currentNodePath = nil;
		
	[super dealloc];
}

- (void)resetSmil;
{
	_currentNode = nil;
	currentNodePath = nil;
	_xmlSmilDoc = nil;
}

- (BOOL)openWithContentsOfURL:(NSURL *)aURL 
{
	NSError *theError;
	BOOL openedOk = NO;
	
	// check that we are opening a new file
	if(![aURL isEqualTo:_currentFileURL])
	{
		[self resetSmil];
		_currentFileURL = [aURL copy];
		// open the URL
		
		_xmlSmilDoc = [[NSXMLDocument alloc] initWithContentsOfURL:_currentFileURL options:NSXMLDocumentTidyXML error:&theError];
		
		if(_xmlSmilDoc != nil)
		{
			// get the first par node
			NSArray *nodes = nil;
			nodes = [_xmlSmilDoc nodesForXPath:@"/smil[1]/body[1]//audio[1]" error:nil];
			_currentNode = ([nodes count]) ? [[nodes objectAtIndex:0] parent] : nil;
			if(_currentNode)
				openedOk = YES;
		}
		
	}
	else // we passed in a URL that is already open. 
		// this will happen if multiple control document id tags point to the same smil file
		// or there is only a single smil file for the whole book
		openedOk = YES;
	
	return openedOk;
}

// return an array of dictionarys each containing a chapter marker for the filename
// the name of the chapter is the id tag and we also add the full path of the node that the 
// id tag is in.
- (NSArray *)audioChapterMarkersForFilename:(NSString *)aFile WithTimescale:(long)aScale
{
	NSMutableArray *chapMarkers = [[NSMutableArray alloc] init];
	NSString *queryStr = [NSString stringWithFormat:@"/smil[1]/body[1]/seq[1]/(.//par[audio[@src='%@']])",aFile];
	
	NSArray *parNodes = nil;
	parNodes = [[_xmlSmilDoc rootElement] nodesForXPath:queryStr error:nil];
	if(![parNodes count])
	{   // no par nodes found so try another approach used for smil files 
		queryStr = [NSString stringWithFormat:@"/smil[1]/body[1]/seq[1]/(.//audio[@src='%@'])",aFile];
		parNodes = [NSArray arrayWithArray:[[_xmlSmilDoc rootElement] nodesForXPath:queryStr error:nil]];
	}
		
		
	for(NSXMLNode *theNode in parNodes)
	{
		NSMutableArray *items = [[[NSMutableArray alloc] init] autorelease];
		NSString *chapName = nil;
		NSString *xPathStr = [theNode XPath];
		//get the textual reference id from the par node if that doesnt work extract it from the text node
		[items addObjectsFromArray:[theNode objectsForXQuery:@"./data(@id)" error:nil]];
		if([items count])
			chapName = [[items objectAtIndex:0] copy];
		else
		{	
			[items addObjectsFromArray:[theNode objectsForXQuery:@".//text/data(@src)" error:nil]];
			chapName = ([items count]) ? [self idTagFromSrcString:[items objectAtIndex:0]] : nil;
		}
		
		// extract the start time if the id and convert it to a QTTime format
		[items removeAllObjects];
		[items addObjectsFromArray:[theNode objectsForXQuery:@".//data(@clip-begin|@clipBegin)" error:nil]];
		NSString *timeStr = ([items count]) ? [NSString QTStringFromSmilTimeString:[items objectAtIndex:0] withTimescale:aScale] : nil ;  
		
		// if we got a chapter nam and a time string create a chapter container and add the data
		// we also add the xpath of the node for the given marker as it is used for restarting playback at a given time.
		if(chapName && timeStr)
		{
			NSDictionary *thisChapter = [[NSDictionary alloc] initWithObjectsAndKeys:[NSValue valueWithQTTime:(QTTimeFromString(timeStr))],QTMovieChapterStartTime,
										 chapName,QTMovieChapterName,
										 xPathStr,@"XPath",
										 nil];
			[chapMarkers addObject:thisChapter];
		}
		
	}
	
	return ([chapMarkers count]) ? chapMarkers : nil;
}



- (BOOL)audioAfterCurrentPosition
{
	NSXMLNode *nextNode = nil;
	NSXMLNode *theNode = _currentNode;
	
	nextNode = [theNode nextSibling];
	if(!nextNode) 
	{
		nextNode = [[theNode parent] nextSibling];
		if(nextNode)
		{	
			if([[nextNode name] isEqualToString:@"seq"])
				if(([[nextNode XPath] isEqualToString:@"/smil[1]/body[1]/seq[1]"]))
					return NO;
		}
		else 
			return NO;
	}

	if(([[nextNode name] isEqualToString:@"par"]) || ([[nextNode name] isEqualToString:@"seq"]))
	{
		NSArray *newAudioNodes = nil;
		newAudioNodes = [nextNode nodesForXPath:@".//audio[@clip-Begin|@clipBegin]" error:nil];
		// check we found some audio content 
	
			if([newAudioNodes count])
			{   
				NSXMLNode *tempnode = [[newAudioNodes objectAtIndex:0] parent];
				_currentNode = tempnode;
				currentNodePath = [_currentNode XPath];
				return YES;
			}
	}
	
	return NO;
	 
}

- (void)setCurrentNodeWithPath:(NSString *)aNodePath
{
	NSError *theError;
	if(aNodePath)
		_currentNode = [[_xmlSmilDoc nodesForXPath:aNodePath error:&theError] objectAtIndex:0];
}

- (void)jumpToNodeWithIdTag:(NSString *)aTag
{
	if(aTag)
	{	
		NSString *queryStr = [NSString stringWithFormat:@"/smil[1]/body[1]//*[@id='%@']",aTag];
		NSArray *tagNodes = nil;
		tagNodes = [_xmlSmilDoc nodesForXPath:queryStr error:nil];
		
		_currentNode = ([tagNodes count]) ? [tagNodes objectAtIndex:0] : _currentNode;
	}
}

- (NSString *)currentIdTag
{
	
	NSArray *idTags = nil;
	idTags = [_currentNode objectsForXQuery:@"./data(@id)" error:nil];
	
	return ([idTags count]) ? [idTags objectAtIndex:0] : nil;
}

- (NSString *)relativeAudioFilePath
{
	NSArray *audioFilenames = [_currentNode objectsForXQuery:@".//audio/data(@src)" error:nil];
	
	if([audioFilenames count])
		if(![self isCompoundString:[audioFilenames objectAtIndex:0]])
			return [audioFilenames objectAtIndex:0];
		else
			return [self filenameFromCompoundString:[audioFilenames objectAtIndex:0]];
	
return nil;
}

- (NSString *)relativeTextFilePath
{
	NSArray *textFilenames = [_currentNode objectsForXQuery:@".//text/data(@src)" error:nil];
	if([textFilenames count])
		if(![self isCompoundString:[textFilenames objectAtIndex:0]])
			return [textFilenames objectAtIndex:0];
		else
			return [self filenameFromCompoundString:[textFilenames objectAtIndex:0]];

	return nil;
}

- (void)nextTextPlaybackPoint
{

	NSXMLNode *nextNode = nil;
	NSXMLNode *theNode = _currentNode;
	
	nextNode = [theNode nextSibling];
//	if(!nextNode) 
//	{
//		nextNode = [[theNode parent] nextSibling];
//		if(nextNode)
//		{	
//			if([[nextNode name] isEqualToString:@"seq"])
//				if(([[nextNode XPath] isEqualToString:@"/smil[1]/body[1]/seq[1]"]))
//					
//		}
//		else 
//			return NO;
//	}
//	
	if(([[nextNode name] isEqualToString:@"par"]) || ([[nextNode name] isEqualToString:@"seq"]))
	{
		NSArray *textNodes = nil;
		textNodes = [[nextNode children] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name == text"]]; 
//		NSArray *newAudioNodes = nil;
//		newAudioNodes = [nextNode nodesForXPath:@".//audio[@clip-Begin|@clipBegin]" error:nil];
//		// check we found some audio content 
//		
//		if([newAudioNodes count])
//		{   
//			NSXMLNode *tempnode = [[newAudioNodes objectAtIndex:0] parent];
//			_currentNode = tempnode;
//			currentNodePath = [_currentNode XPath];
//			return YES;
//		}
	}
//	
//	return NO;
	
}

- (void)previousPlaybackPoint
{
	
}

@synthesize _xmlSmilDoc, _currentFileURL, _currentNode, currentNodePath;

@end



@implementation TBSMILDocument (Private)

- (BOOL)isCompoundString:(NSString *)aString
{
	return (([aString rangeOfString:@"#"].location) == NSNotFound) ? NO : YES;
}

- (NSString *)filenameFromCompoundString:(NSString *)aString
{
	// get the position of the # symbol in the string which is the delimiter between filename and ID tag
	NSInteger position = [aString rangeOfString:@"#"].location;
	return ((position > 0) ? [aString substringToIndex:position] : nil); 
}

- (NSString *)idTagFromSrcString:(NSString *)anIdString
{
	NSAssert(anIdString != nil, @"anIdString is nil");
	// get the position of the # symbol in the string which is the delimiter between filename and ID tag
	NSInteger markerPos = [anIdString rangeOfString:@"#"].location;
	return (markerPos > 0) ? [anIdString substringFromIndex:(markerPos+1)] : nil;
}



@end
