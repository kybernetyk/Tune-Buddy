//
//  LastFMNotificationOperation.m
//  Tune Buddy
//
//  Created by jrk on 14/5/10.
//  Copyright 2010 Flux Forge. All rights reserved.
//

#import "LastFMNotificationOperation.h"
#import "FMEngine.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "JSON.h"
#import "LastFMAuth.h"

@implementation LastFMNotificationOperation
@synthesize delegate;


@synthesize artistName;
@synthesize trackName;
@synthesize albumName;
@synthesize trackLength;
@synthesize trackPlaybackStartTime;



- (void) main
{
	NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];
	NSString *username = [[LastFMAuth sharedLastFMAuth] username];
	
	if (!username)
	{
		
		NSLog(@"LastFM Notification op: no username set!");
		[delegate performSelectorOnMainThread:@selector(lastFmScrobblerNotificationDidFail:) withObject: self waitUntilDone: YES];
		[thePool release];
		return;
	}
	
	if (![self artistName] || ![self trackName] || ![self albumName] ||
		![self trackLength] || ![self trackPlaybackStartTime])
	{
		NSLog(@"one of the datas is nil!");
		[delegate performSelectorOnMainThread:@selector(lastFmScrobblerNotificationDidFail:) withObject: self waitUntilDone: YES];
		[thePool release];
		return;
	}
		
	


	
	FMEngine *fmEngine = [[FMEngine alloc] init];
	
	
	NSString *secretKey = [[LastFMAuth sharedLastFMAuth] secretKey];
	NSLog(@"secret key: %@", secretKey);
	
	if (!secretKey)
	{
		NSLog(@"secret key = nil :(");
		[delegate performSelectorOnMainThread:@selector(lastFmScrobblerNotificationDidFail:) withObject: self waitUntilDone: YES];
		[fmEngine release];
		[thePool release];
		return;
	}
	
	
	NSLog(@"secret key: %@", secretKey);
	
	//	NSLog(@"auth response: %@", str);
	
	//timestamp lol
	NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
	NSNumber *n = [NSNumber numberWithDouble: interval];
	NSNumber *n2 = [NSNumber numberWithInt: [n intValue]];
	NSNumber *n3 = [NSNumber numberWithInt: [[self trackPlaybackStartTime] timeIntervalSince1970]];  //[NSNumber numberWithInt: ([n intValue] - 100)];
	NSString *authToken = [fmEngine scrobbleAuthToken: n2];
	[fmEngine release];
	
	
	//handshake lol
	//TODO: Parse the data (json) for session key ("0ed ...")
	NSString *urlstring = [NSString stringWithFormat: @"http://post.audioscrobbler.com/?hs=true&p=1.2.1&c=tnb&v=1.0&u=%@&t=%@&a=%@&api_key=%@&sk=%@", username,n2 ,authToken,_LASTFM_API_KEY_, secretKey];
	
	//	NSLog(@"urlstring: %@", urlstring);
	NSString *resp = [NSString stringWithContentsOfURL: [NSURL URLWithString: urlstring]];
	if (!resp)
	{	
		[delegate performSelectorOnMainThread:@selector(lastFmScrobblerNotificationDidFail:) withObject: self waitUntilDone: YES];
		[thePool release];
		return;
	}
	
	//	NSLog(@"resp: %@",resp);
	
	NSArray *respArray = [resp componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
	
	//if resparray[0] != OK ... error 
	NSString *sessionID = [NSString stringWithString: [respArray objectAtIndex: 1]];
	NSString *nowplayingURL = [NSString stringWithString: [respArray objectAtIndex: 2]];
		NSLog(@"session: %@",sessionID);
	
	//	NSLog(@"time: %@",n3);
	
	
	ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString: nowplayingURL]]; // log in & get cookies
	[request setPostValue: sessionID forKey: @"s"];
	[request setPostValue: [self artistName] forKey: @"a"];
	[request setPostValue: [self trackName] forKey: @"t"];
	[request setPostValue: [self albumName] forKey: @"b"];
	//	 [request setPostValue: @"" forKey: @"l"];
	[request setPostValue: [NSString stringWithFormat: @"%i",[[self trackLength] intValue]] forKey: @"l"];
	[request setPostValue: @"" forKey: @"n"];
	[request setPostValue: @"" forKey: @"m"];
	
	[request startSynchronous];
	
	NSLog(@"scrobble notification returned: %@",[request responseString]);
	[request release];
	
	//[delegate lastFMScrobbler: self submissionDidSucceed: YES];
	[delegate performSelectorOnMainThread:@selector(lastFmScrobblerNotificationDidSucceed:) withObject: self waitUntilDone: YES];
	

	[thePool release];
}


- (void) dealloc
{
	NSLog(@"Last FM Notification Operation dealloc!");

	
	[self setArtistName: nil];
	[self setTrackName: nil];
	[self setAlbumName: nil];
	[self setTrackLength: nil];
	[self setTrackPlaybackStartTime: nil];
	
	[super dealloc];
}

@end
