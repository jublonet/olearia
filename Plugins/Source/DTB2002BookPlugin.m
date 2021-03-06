//
//  DTB2002BookPlugin.m
//  StdDaisyFormats
//
//  Created by Kieren Eaton on 20/05/09.
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


#import "DTB2002BookPlugin.h"
#import "TBOPFDocument.h"
#import "TBNCXDocument.h"
#import "TBNavigationController.h"
#import "TBTextOnlyNavigationController.h"

@interface DTB2002BookPlugin ()



@end

@interface DTB2002BookPlugin (Private)

- (BOOL)canOpenBook:(NSURL *)bookURL;

@end

@implementation DTB2002BookPlugin

- (BOOL)openBook:(NSURL *)bookURL
{
	BOOL opfLoaded = NO;
	BOOL ncxLoaded = NO;
	BOOL navConDidLoad = NO;
	NSURL *controlFileURL = nil;
	NSURL *packageFileUrl = nil;
	TBControlDoc *controlDoc = nil;
	TBPackageDoc *packageDoc = nil;
	TalkingBookMediaFormat mediaFormat = UnknownMediaFormat;
	
	// do a sanity check first to see that we can attempt to open the book. 
	if([self canOpenBook:bookURL])
	{
		// first check if we were passed a folder
		if ([fileUtils URLisDirectory:bookURL])
		{	
			bookData.baseFolderPath = bookURL;
			// passed a folder so first check for an OPF file 
			packageFileUrl = [fileUtils fileURLFromFolder:[bookData.baseFolderPath path]  WithExtension:@"opf"];
			// check if we found the OPF file
			if (!packageFileUrl)
				// no opf file found so check for the NCX file
				controlFileURL = [fileUtils fileURLFromFolder:[bookData.baseFolderPath path] WithExtension:@"ncx"];
		}
		else
		{
			// valid file url passed in
			NSString *filename = [bookURL path];
			// check for an opf extension
			if(YES == [[[filename pathExtension] lowercaseString] isEqualToString:@"opf"])
			{
				packageFileUrl = bookURL;
			}
			else if(YES == [[[filename pathExtension] lowercaseString] isEqualToString:@"ncx"])
			{
				// check if there is an OPF file to use instead
				packageFileUrl = [fileUtils fileURLFromFolder:[bookURL path] WithExtension:@"opf"];
				// check if we found the OPF file
				if (!packageFileUrl)
				{
					// no OPF file found fall back to the ncx one instead
					// this should not happen that often but might occasionally 
					// with badly authored books.
					controlFileURL = bookURL;  
				}
			}
		}
		
		if(packageFileUrl)
		{

			packageDoc = [[[TBOPFDocument alloc] init] autorelease];
			
			if([packageDoc openWithContentsOfURL:packageFileUrl])
			{
				// the opf file opened correctly
				// get the dc:Format node string
				NSString *bookFormatString = [[packageDoc stringForXquery:@"/package/metadata/dc-metadata/data(*:Format)" ofNode:[packageDoc metadataNode]] uppercaseString];
				if(YES == [bookFormatString hasSuffix:@"Z39.86-2002"])
				{
					// the opf file specifies that it is a 2002 format book
					if(!bookData.baseFolderPath)
						bookData.baseFolderPath = [NSURL fileURLWithPath:[[packageFileUrl path] stringByDeletingLastPathComponent] isDirectory:YES];
					
					// get the ncx filename
					packageDoc.ncxFilename = [packageDoc stringForXquery:@"/package/manifest/item[@media-type='text/xml' ] [ends-with(@href,'.ncx')] /data(@href)" ofNode:nil];
					if(packageDoc.ncxFilename)
						controlFileURL = [NSURL fileURLWithPath:[[[bookData baseFolderPath] path] stringByAppendingPathComponent:packageDoc.ncxFilename]];
						
					// get the text content filename
					packageDoc.textContentFilename = [packageDoc stringForXquery:@"/package/manifest/item[@media-type='text/xml'][starts-with(@id,'Text')]/data(@href)" ofNode:nil];
					
					[packageDoc processData];
					
					opfLoaded = YES;
				}
				
				
			}
			else 
			{	
				
				// opening the opf failed for some reason so try to open just the control file
				controlFileURL = [fileUtils fileURLFromFolder:[[packageFileUrl path] stringByDeletingLastPathComponent] WithExtension:@"ncx"];
			}
		}
		
		if (controlFileURL)
		{
			if(!controlDoc)
				controlDoc = [[[TBNCXDocument alloc] init] autorelease];
			
			// attempt to load the ncx file
			if([controlDoc openWithContentsOfURL:controlFileURL])
			{
				// check if the folder path has already been set
				if (!bookData.baseFolderPath)
					bookData.baseFolderPath = [[NSURL alloc] initFileURLWithPath:[[controlFileURL path] stringByDeletingLastPathComponent] isDirectory:YES];
				
				[controlDoc processData];

				ncxLoaded = YES;
			}
			else
				self.navCon.controlDocument = nil;
		}
		
		if(ncxLoaded || opfLoaded)
		{
			mediaFormat = [self mediaFormatFromString:[packageDoc mediaFormatString]];
			navConDidLoad = [self loadCorrectNavControllerForBookFormat:mediaFormat];
			
			if (navConDidLoad) 
			{
				self.navCon.bookMediaFormat = mediaFormat;
				if(opfLoaded)
				{	
					self.navCon.packageDocument = packageDoc;

					self.currentPlugin = self;
				}
				
				if(ncxLoaded)
				{	
					self.navCon.controlDocument = controlDoc;
					self.currentPlugin = self;
				}
				
				[navCon prepareForPlayback];
				
				
			}
			else
				[bookData resetData];
		}
		
	}
	else
		if(navCon)
			[navCon resetController];
	
	// return YES if the Package document and/or Control Document loaded correctly
	// as we can do limited control and playback functions from the opf file this is a valid scenario.
	return ((opfLoaded || ncxLoaded) && navConDidLoad);
}

- (NSString *)FormatDescription
{
	return LocalizedStringInTBStdPluginBundle(@"This Book has been authored with the Daisy 2002 standard",@"Daisy 2002 Standard description");
}

+ (DTB2002BookPlugin *)bookType
{
	DTB2002BookPlugin *instance = [[[self alloc] init] autorelease];
	if (instance)
	{	
		[instance setupPluginSpecifics];
		return instance;
	}
	
	return nil;
}

- (void)setupPluginSpecifics
{
	validFileExtensions = [[NSArray  alloc] initWithObjects:@"opf",@"ncx",nil];
}


- (NSURL *)loadedURL
{
	if(navCon.packageDocument)
		return navCon.packageDocument.fileURL;
	if(navCon.controlDocument)
		return navCon.controlDocument.fileURL;
	
	return nil;
}


- (NSXMLNode *)infoMetadataNode
{
	if(navCon.packageDocument)
		return [[navCon packageDocument] metadataNode];
	if(navCon.controlDocument)
		return [[navCon controlDocument] metadataNode];
	
	return nil;
}

- (void) dealloc
{
	[super dealloc];
}

@end


@implementation DTB2002BookPlugin (Private)

// this method checks the url for a file with a valid extension
// if a directory URL is passed the directory is scanned for a file with a valid extension
- (BOOL)canOpenBook:(NSURL *)bookURL;
{
	NSURL *fileURL = nil;
	// first check if we were passed a folder
	if ([fileUtils URLisDirectory:bookURL])
	{	// we were so first check for an OPF file 
		fileURL = [fileUtils fileURLFromFolder:[bookURL path] WithExtension:@"opf"];
		// check if we found the OPF file
		if (!fileURL)
			// check for the NCX file
			fileURL = [fileUtils fileURLFromFolder:[bookURL path] WithExtension:@"ncx"];
		if (fileURL)
			return YES;		
	}
	else
	{
		// check the path contains a file with a valid extension
		if([fileUtils URL:bookURL hasExtension:validFileExtensions])
			return YES;
	}
	
	// this did not find a valid extension that it could attempt to open
	return NO;
}


@end




