//
//  TBTextOnlyNavigationController.m
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 3/07/09.
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



#import "TBTextOnlyNavigationController.h"
#import "TBOPFDocument.h"
#import "TBNCXDocument.h"
#import "TBSMILDocument.h"

@interface TBTextOnlyNavigationController ()



@end


@implementation TBTextOnlyNavigationController

- (id) init
{
	self = [super init];
	if (self != nil) 
	{
		[mainSpeechSynth setDelegate:self];
	}
	
	return self;
}

- (void) dealloc
{
	
	[super dealloc];
}

- (void)prepareForPlayback
{
	[self resetController];
	
	
	if(controlDocument)
	{
		NSString *filename = [controlDocument contentFilenameFromCurrentNode];
		if([[filename pathExtension] isEqualToString:@"smil"])
		{
			
			
			if(!smilDocument)
				smilDocument = [[TBSMILDocument alloc] init];
			
			// check if the smil file REALLY needs to be loaded
			// Failsafe for single smil books 
			if(![_currentSmilFilename isEqualToString:filename])
			{
				_currentSmilFilename = [filename copy];
				[smilDocument openWithContentsOfURL:[NSURL URLWithString:_currentSmilFilename relativeToURL:bookData.baseFolderPath]];
			}
			
			// set the smil file to the correct start point for navigation and playback
			_currentTag = [controlDocument currentIdTag];
			[smilDocument jumpToNodeWithIdTag:_currentTag];
			
			filename = [smilDocument relativeTextFilePath];
			if(filename)
			{
				if(!textDocument)
					textDocument = [[TBTextContentDoc alloc] init];
				
				if(![_currentTextFilename isEqualToString:filename])
				{
					_currentTextFilename = [filename copy];
					[textDocument openWithContentsOfURL:[NSURL URLWithString:_currentTextFilename relativeToURL:bookData.baseFolderPath]];
				}
				[textDocument jumpToNodeWithIdTag:_currentTag];
				[textDocument updateDataAfterJump];
				_contentToSpeak = [textDocument contentText];
			}
			else // no audio filenames found 
			{
				
			}



		}
		else
		{
			// no smil filename so look for the text filename in the control document
			
		}
		
	}
	else if(packageDocument)
	{
		// setup for package navigation
	}
	
	
}

//- (void)resetController
//{
//	
//	_currentSmilFilename = nil;
//	_currentTextFilename = nil;
//	_currentTag = nil;
//	_didUserNavigationChange = NO;
//	_mainSynthIsSpeaking = NO;
//	
//	// call the supers resetController method which
//	// will remove us from the notification center
//	[super resetController];
//	
//	
//}


- (void)startPlayback
{
	if(_mainSynthIsSpeaking && !bookData.isPlaying)
		[mainSpeechSynth continueSpeaking];
	else
	{
		
		
		[mainSpeechSynth startSpeakingString:_contentToSpeak];
		
	}
	
	bookData.isPlaying = YES;
}

- (void)stopPlayback
{
	_mainSynthIsSpeaking = [mainSpeechSynth isSpeaking];
	[mainSpeechSynth pauseSpeakingAtBoundary:NSSpeechWordBoundary];
	
	bookData.isPlaying = NO;
}

- (void)nextElement
{
	if(controlDocument)
	{	
		[controlDocument moveToNextSegmentAtSameLevel];
		_currentTag = [controlDocument currentIdTag];
	}
	
	_didUserNavigationChange = YES;
	
	[super updateAfterNavigationChange];

	//[textDocument startSpeakingFromIdTag:_currentTag];
}

- (void)previousElement
{
	if(controlDocument)
	{	
		[controlDocument moveToPreviousSegment];
		_currentTag = [controlDocument currentIdTag];
	}
	
	_didUserNavigationChange = YES;
	
	[super updateAfterNavigationChange];
	
	//[textDocument startSpeakingFromIdTag:_currentTag];
}

- (void)goUpLevel
{
	if(controlDocument)
	{	
		[controlDocument goUpALevel];
		_currentTag = [controlDocument currentIdTag];
	}
	
	_didUserNavigationChange = YES;
	_mainSynthIsSpeaking = NO;
	[self updateAfterNavigationChange];
	
	[textDocument jumpToNodeWithIdTag:_currentTag];
	[textDocument updateDataAfterJump];
	
	[self speakLevelChange];

	
}

- (void)goDownLevel
{
	if(controlDocument)
	{	
		[controlDocument goDownALevel];
		_currentTag = [controlDocument currentIdTag];
	}
	_didUserNavigationChange = YES;
	_mainSynthIsSpeaking = NO;
	[self updateAfterNavigationChange];
	
	[textDocument jumpToNodeWithIdTag:_currentTag];
	[textDocument updateDataAfterJump];
	
	[self speakLevelChange];
	
}

- (void)moveControlPoint:(NSString *)aNodePath withTime:(NSString *)aTime
{
	// the control document will always be our first choice for navigation
	if(controlDocument)
	{	
		[controlDocument jumpToNodeWithPath:aNodePath];
		_currentTag = [controlDocument currentIdTag];
	}
	else if(packageDocument)
	{
		// need to add navigation methods for package documents
	}
	
	_didUserNavigationChange = YES;
	
	[textDocument jumpToNodeWithIdTag:_currentTag];
	
	[self updateAfterNavigationChange];
	[textDocument updateDataAfterJump];
	
}

- (NSString *)currentNodePath
{
	if(controlDocument)
		return [controlDocument currentPositionID];
	
	return nil;
}

- (NSString *)currentTime
{	
	// return nil as there is no time sig in textOnly
	// books
	
	return nil;
}

- (void)updateAfterNavigationChange
{
	
	[textDocument updateDataForCurrentPosition];
	
}

@end

@implementation TBTextOnlyNavigationController (SpeechDelegate)

- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)success
{
	if(sender == mainSpeechSynth)
	{	
		if (!_didUserNavigationChange)
		{
			if (controlDocument)
			{
				[controlDocument moveToNextSegment];
				[controlDocument updateDataForCurrentPosition];
				_currentTag = [controlDocument currentIdTag];
				[textDocument jumpToNodeWithIdTag:_currentTag];
				_contentToSpeak = [textDocument contentText];
				[self startPlayback];
			}
		}
		//		if(_mainSynthIsSpeaking)
		//			[mainSpeechSynth continueSpeaking];
		//				else
		//				{	
		//				if(!_didUserNavigationChange)
		//					[[NSNotificationCenter defaultCenter] postNotificationName:TBAuxSpeechConDidFinishSpeaking object:self];
		//					else
		//					{	
		//						_didUserNavigationChange = NO;
		//					[[NSNotificationCenter defaultCenter] postNotificationName:TBAuxSpeechConDidFinishSpeaking object:self];
		//				}
		
		
		
	}
	
	
}

- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender willSpeakWord:(NSRange)wordToSpeak ofString:(NSString *)text
{
	//	if(sender == mainSpeechSynth)
	//	{
	//		//NSLog(@"word num is %d",wordToSpeak.location);
	//	}
	// send a notifcation or tell the web/text view to 
	//highlight the current word about to be spoken
	//NSString *wordIs = [text substringWithRange:wordToSpeak];
	//NSLog(@"speaking -> %@",wordIs);
}


@end

