//
//  FacebookShareOperation.m
//  Tune Buddy
//
//  Created by jrk on 26/9/10.
//  Copyright 2010 Flux Forge. All rights reserved.
//

#import "FacebookShareOperation.h"
#import "NSString+Search.h"
#import "NSString+URLEncoding.h"
#import "NSString+SBJSON.h"
#import "SBJSON.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "NSString+Slice.h"
#import "FMEngine.h"

@implementation FacebookShareOperation
@synthesize delegate;
@synthesize message;
@synthesize albumArt;
@synthesize artworkURL;
@synthesize trackviewURL;
@synthesize	trackArtist;
@synthesize trackName;
@synthesize albumName;
@synthesize trackRating;
@synthesize trackPlayCount;

- (void) messageDelegateSuccess
{
	[delegate performSelectorOnMainThread: @selector(facebookShareOperationDidSucceed:) withObject: self waitUntilDone: YES];
}

- (void) messageDelegateFailure
{
	[delegate performSelectorOnMainThread: @selector(facebookShareOperationDidFail:) withObject: self waitUntilDone: YES];
}

- (void) dealloc
{
	[self setMessage: nil];
	[self setAlbumArt: nil];
	[self setArtworkURL: nil];
	[self setTrackviewURL: nil];
	[self setTrackArtist: nil];
	[self setTrackName: nil];
	[self setAlbumName: nil];
	[self setTrackRating: nil];
	[self setTrackPlayCount: nil];

	NSLog(@"share op dealloc!");
	[super dealloc];
}

- (NSString *) uploadAlbumArt
{
	if (![self albumArt])
		return nil;
	
	NSBitmapImageRep *rep = [[[NSBitmapImageRep alloc] initWithData:[[self albumArt] TIFFRepresentation]] autorelease];
	NSData *data = [rep representationUsingType: NSJPEGFileType properties: nil];
	
	ASIFormDataRequest *req = [[[ASIFormDataRequest alloc] initWithURL: [NSURL URLWithString: @"http://htlr.org/upload/uploadFile"]] autorelease];
	[req setData: data forKey: @"upload[datafile]"];
	[req startSynchronous];

	NSString *returnValue = [req responseString];

	if (!returnValue || [returnValue length] == 0)
		return nil;
	
	if ([returnValue containsString: @"fail" ignoringCase: YES])
		return nil;

	NSLog(@"upload ret: %@", returnValue);

	NSString *url = [[returnValue componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]] objectAtIndex: 0];
	url = [url stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];

	[self setArtworkURL: url];
	[self setTrackviewURL: url];
	return url;
}

- (void) getArtworkURLFromLastFM
{
	//http://www.last.fm/api/show?service=356
	//http://ws.audioscrobbler.com/2.0/?method=track.getinfo&api_key=b25b959554ed76058ac220b7b2e0a026&artist=cher&track=believe
	//_LASTFM_API_KEY_
	
	NSString *urlString = [NSString stringWithFormat: @"http://ws.audioscrobbler.com/2.0/?method=track.getinfo&api_key=%@&artist=%@&track=%@",
						   _LASTFM_API_KEY_,
						   [[self trackArtist] URLEncodedString],
						   [[self trackName] URLEncodedString]];
						   
	NSLog(@"url: %@",urlString);						   
						   
	NSURL *url = [NSURL URLWithString: urlString];
	ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL: url];
	[req startSynchronous];
	
	NSString *responseString = [req responseString];

	
	NSString *trackURL = [responseString stringBetweenSubstringOne: @"<URL>" andSubstringTwo: @"</URL>" ignoringCase: YES];
	NSLog(@"trackURL: %@", trackURL);
	[self setTrackviewURL: trackURL];
	
	NSLog(@"%@",responseString);
	NSInteger start = [responseString indexOfSubstring: @"<ALBUM" ignoringCase: YES];
	NSInteger stop = [responseString indexOfSubstring: @"</ALBUM>" ignoringCase: YES];
	if (start == NSNotFound || stop == NSNotFound)
		return;
	stop += [@"</ALBUM>" length];
	
//	NSLog(@"start: %i", start);
//	NSLog(@"stop: %i", stop);
	
	NSString *albumChunk = [responseString stringBySlicingFrom: start to: stop];
	NSLog(@"albumchunk: %@", albumChunk);
	
	NSString *albumURL = [albumChunk stringBetweenSubstringOne: @"<URL>" andSubstringTwo: @"</URL>" ignoringCase: YES];
	NSLog(@"albumURL: %@", albumURL);
	
	
	//now get the image url by trying
/*	<image size="small">http://userserve-ak.last.fm/serve/64s/5617239.jpg</image>
	<image size="medium">http://userserve-ak.last.fm/serve/126/5617239.jpg</image>
	<image size="large">http://userserve-ak.last.fm/serve/174s/5617239.jpg</image>
	<image size="extralarge">http://userserve-ak.last.fm/serve/300x300/5617239.jpg</image>*/
	
	NSString *imageURL = nil;
	imageURL = [albumChunk stringBetweenSubstringOne: @"<IMAGE size=\"extralarge\">" andSubstringTwo: @"</IMAGE>" ignoringCase: YES];

	if (!imageURL)
		imageURL = [albumChunk stringBetweenSubstringOne: @"<IMAGE size=\"large\">" andSubstringTwo: @"</IMAGE>" ignoringCase: YES];
	if (!imageURL)
		imageURL = [albumChunk stringBetweenSubstringOne: @"<IMAGE size=\"medium\">" andSubstringTwo: @"</IMAGE>" ignoringCase: YES];
	if (!imageURL)
		imageURL = [albumChunk stringBetweenSubstringOne: @"<IMAGE size=\"small\">" andSubstringTwo: @"</IMAGE>" ignoringCase: YES];
	
	NSLog(@"image url: %@", imageURL);

	[self setArtworkURL: imageURL];

}


- (void) getArtworkURLFromiTunesIncludingAlbumForSearch: (BOOL) withAlbum
{
	//http://ax.phobos.apple.com.edgesuite.net/WebObjects/MZStoreServices.woa/wa/wsSearch?term=Fettes+Brot+An+Tagen+Wie+diesen
	
	NSString *term = nil;
	
	if (withAlbum)
	{	
		term = [NSString stringWithFormat:@"%@ %@ %@",
		 [self trackArtist],
		 [self trackName],
				[self albumName]];
	}
	else
	{
		term = [NSString stringWithFormat:@"%@ %@",
		 [self trackArtist],
		 [self trackName]];
	}
	
	
	NSString *stringURL = [NSString stringWithFormat: @"http://ax.phobos.apple.com.edgesuite.net/WebObjects/MZStoreServices.woa/wa/wsSearch?term=%@",
							[term URLEncodedString]];
	NSLog(@"search url: %@",stringURL);
	
	NSURL *url = [NSURL URLWithString: stringURL];
	NSString *ret = [NSString stringWithContentsOfURL: url];
	
	
	NSDictionary *dict = [ret JSONValue];

	NSArray *results = [dict objectForKey: @"results"];
	
	for (NSDictionary *result in results)
	{
		NSString *arturl = [result objectForKey: @"artworkUrl100"];
		if (arturl && [arturl length] > 0)
		{	
			[self setArtworkURL: arturl];
			[self setTrackviewURL: [result objectForKey: @"trackViewUrl"]];
			return;
		}
	}
	
	if (withAlbum)
	{
		[self getArtworkURLFromiTunesIncludingAlbumForSearch: NO];
	}
}

- (void) extendedPost
{
	//[self getArtworkURLFromiTunesIncludingAlbumForSearch: YES];
	[self getArtworkURLFromLastFM];
	//[self uploadAlbumArt];
	NSLog(@"artwork url: %@", [self artworkURL]);
	NSLog(@"track view: %@", [self trackviewURL]);
//	return;
//	NSString *albumArtURL = [self uploadAlbumArt];
	
	

	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	NSString *token = [[defs objectForKey: @"facebookAccessToken"] URLDecodedString]; //no url encode please!
	if (!token)
	{
		NSLog(@"no token found. please auth!");
		[self messageDelegateFailure];
		return;
	}

	SBJSON *json = [[[SBJSON alloc] init] autorelease];
	
	NSMutableDictionary *attachment = [NSMutableDictionary dictionary];
	
	
	//our info text for this entry
	if ([self albumName] && [self trackArtist] && [self trackName])
	{
		NSString *captionString = nil;
		
		if ([[self trackRating] integerValue] > 0)
		{		
			captionString = [NSString stringWithFormat: @"{*actor*} rated this track with %i/5",
						   [[self trackRating] intValue]/20];					 
		}

		if ([[self trackPlayCount] intValue] > 0)
		{
			if (!captionString)
			{	
				captionString = [NSString stringWithFormat: @"{*actor*} listened to this track %i times.",
								 [[self trackPlayCount] integerValue]];
			}
			else
			{
				captionString = [captionString stringByAppendingFormat: @" and listened to it %i times.",
								 [[self trackPlayCount] integerValue]];
			}
		}
		else 
		{
			captionString = [captionString stringByAppendingString: @"."];
		}

		if (captionString)
		{	
			[attachment setObject: captionString forKey: @"caption"];
		}

		///////////////////////////////

		NSString *descriptionString = [NSString stringWithFormat: @"'%@' by '%@' from the Album '%@'. ",
									   [self trackName],
									   [self trackArtist],
									   [self albumName]];
		
		if (descriptionString)
		{
			[attachment setObject: descriptionString forKey: @"description"];
		}
	}
	

	//let's attach the image
	NSString *strAttachment = nil;
	if ([self artworkURL])
	{
		NSMutableDictionary *picture = [NSMutableDictionary dictionary];
		[picture setObject: @"image" forKey: @"type"];
		[picture setObject: [self artworkURL] forKey: @"src"];

		if ([self trackviewURL])
		{	
			//http://itunes.apple.com/us/album/40-1/id395055697?i=395055712&uo=4
			//album/struttin/id203998119?i=203998120

			//this is for iTunes
			/*NSRange r1 = [[self trackviewURL] rangeOfString: @"album/" options: NSCaseInsensitiveSearch];
			
			if (r1.location == NSNotFound)
			{
				[picture setObject: @"http://www.fluxforge.com/tune-buddy/" forKey: @"href"];		
			}
			else
			{
				NSString *id1 = [[self trackviewURL] substringFromIndex: r1.location];
				id1 = [id1 stringByReplacingOccurrencesOfString: @"&uo=4" withString: @""];
				id1 = [id1 stringByReplacingOccurrencesOfString: @"?i=" withString: @"___"];
				
				
				NSString *affliURL = [NSString stringWithFormat: @"http://www.fluxforge.com/tune-buddy/music/%@",
									  id1];
				
				[picture setObject: affliURL forKey: @"href"];
			}*/
			
			//this is for lastgm
			[picture setObject: [self trackviewURL] forKey: @"href"];
			
		}
		else
		{
			[picture setObject: @"http://www.fluxforge.com/tune-buddy/" forKey: @"href"];
			
		}
		
		NSArray *media = [NSArray arrayWithObject: picture];
		[attachment setObject: media forKey: @"media"];
	}
	else
	{
		NSMutableDictionary *picture = [NSMutableDictionary dictionary];
		[picture setObject: @"image" forKey: @"type"];
		[picture setObject: @"http://www.fluxforge.com/tune-buddy/no_artwork.png" forKey: @"src"];
		if ([self trackviewURL])
		{	
			[picture setObject: [self trackviewURL] forKey: @"href"];		
		}
		else
		{
			[picture setObject: @"http://www.fluxforge.com/tune-buddy/" forKey: @"href"];
		}

		NSArray *media = [NSArray arrayWithObject: picture];
		[attachment setObject: media forKey: @"media"];
	}
	
	strAttachment = [json stringWithObject: attachment];	
	NSLog(@"attachment: %@", strAttachment);
	
	NSDictionary *actionLink = [NSDictionary dictionaryWithObjectsAndKeys:
								@"Tune Buddy for Mac", @"text",
								@"http://www.fluxforge.com/tune-buddy/", @"href",
								nil];
	
	NSString *strActionLinks = [json stringWithObject: [NSArray arrayWithObject: actionLink]];
	
	ASIFormDataRequest *req = [[[ASIFormDataRequest alloc] initWithURL: [NSURL URLWithString: @"https://api.facebook.com/method/stream.publish"]] autorelease];
	
	[req setPostValue: token  forKey: @"access_token"];
	[req setPostValue: message forKey: @"message"];
	[req setPostValue: strActionLinks forKey: @"action_links"];
	
	if (strAttachment)
	{	
		[req setPostValue: strAttachment forKey: @"attachment"];
		NSLog(@"submitting with cover art ...");
	}

	[req startSynchronous];
	
	NSString *ret = [req responseString];
	NSLog(@"ret: %@", ret);
	
	if ([ret containsString: @"error_response" ignoringCase: YES])
	{
		[defs removeObjectForKey: @"facebookAccessToken"];
		
		[self messageDelegateFailure];

		return;
	}
	
	[self messageDelegateSuccess];
	return;
}

- (void) simplePost
{
	NSLog(@"sending to fb ...");
	
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	NSString *token = [[defs objectForKey: @"facebookAccessToken"] URLEncodedString];
	if (!token)
	{
		NSLog(@"no token found. please auth!");
		[self messageDelegateFailure];
		return;
	}
	
	NSString *messageText = [[self message] URLEncodedString];
	NSString *callURL = [NSString stringWithFormat: @"https://api.facebook.com/method/stream.publish?access_token=%@&message=%@",
						 token,
						 messageText];
	NSURL *url = [NSURL URLWithString: callURL];
	
	NSError *err;
	NSString *ret = [NSString stringWithContentsOfURL: url encoding: NSUTF8StringEncoding error: &err];
	NSLog(@"fb ret: %@", ret);	
	
	//Invalid OAuth 2.0 Access Token
	if ([ret containsString: @"error_response" ignoringCase: YES])
	{
		[defs removeObjectForKey: @"facebookAccessToken"];
		[defs synchronize];
		[self messageDelegateFailure];
		return;
	}
}

- (void) main
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	if ([defs boolForKey: @"detailedFacebookPost"])
	{
		[self extendedPost];
	}
	else
	{
		[self simplePost];
	}
	[pool drain];
	
	return;
}

@end
