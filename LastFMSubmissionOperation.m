//
//  LastFMSubmissionOperation.m
//  Tune Buddy
//
//  Created by jrk on 12/5/10.
//  Copyright 2010 Flux Forge. All rights reserved.
//

#import "LastFMSubmissionOperation.h"
#import "FMEngine.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "JSON.h"
#import "LastFMAuth.h"

@implementation LastFMSubmissionOperation
@synthesize dictsToSubmit;
@synthesize delegate;

- (void) main
{
	NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];
	NSString *username = [[LastFMAuth sharedLastFMAuth] username];
	if (!username)
	{
		
		NSLog(@"LastFM submission op: no username set!");
		[delegate performSelectorOnMainThread:@selector(lastFmScrobblerSubmissionDidFail:) withObject: self waitUntilDone: YES];
		[thePool release];
		return;
	}
	
	
	NSLog(@"Last FM Submission operation starting ...");
	
	NSLog(@"performing mass scrobble with %i songs ...", [dictsToSubmit count]);
	if ([dictsToSubmit count] <= 0)
	{
		NSLog(@"nothing to submit ...");
		[delegate performSelectorOnMainThread:@selector(lastFmScrobblerSubmissionDidFail:) withObject: self waitUntilDone: YES];
		//[delegate lastFMScrobbler: self submissionDidSucceed: NO];
		
		[thePool release];
		return;
	}
	NSString *secretKey = [[LastFMAuth sharedLastFMAuth] secretKey];
	NSLog(@"secret key: %@", secretKey);
	
	if (!secretKey)
	{
		NSLog(@"secret key = nil :(");
		[delegate performSelectorOnMainThread:@selector(lastFmScrobblerSubmissionDidFail:) withObject: self waitUntilDone: YES];
		[thePool release];

		return;
	}
	
	FMEngine *fmEngine = [[FMEngine alloc] init];
	
	//timestamp lol
	NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
	NSNumber *n = [NSNumber numberWithDouble: interval];
	NSNumber *n2 = [NSNumber numberWithInt: [n intValue]];
	//	NSNumber *n3 = [NSNumber numberWithInt: [[self trackPlaybackStartTime] timeIntervalSince1970]];  //[NSNumber numberWithInt: ([n intValue] - 100)];
	NSString *authToken = [fmEngine scrobbleAuthToken: n2];
	
	[fmEngine release];
	
	NSLog(@"date: %@", [NSDate date]);
	
	//handshake lol
	//TODO: Parse the data (json) for session key ("0ed ...")
	NSString *urlstring = [NSString stringWithFormat: @"http://post.audioscrobbler.com/?hs=true&p=1.2.1&c=tnb&v=1.0&u=%@&t=%@&a=%@&api_key=%@&sk=%@",username,n2 ,authToken,_LASTFM_API_KEY_,secretKey];
	
	NSLog(@"urlstring: %@", urlstring);
	NSError *err;
	NSString *resp = [NSString stringWithContentsOfURL: [NSURL URLWithString: urlstring] encoding: NSUTF8StringEncoding error: &err];
	if (!resp)
	{	
		NSLog(@"no response from handshake.");
		[delegate performSelectorOnMainThread:@selector(lastFmScrobblerSubmissionDidFail:) withObject: self waitUntilDone: YES];
		[thePool release];
		return;
		
	}
	
	NSLog(@"resp: %@",resp);
	
	NSArray *respArray = [resp componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
	
	//if resparray[0] != OK ... error 
	NSString *sessionID = [respArray objectAtIndex: 1];
//	NSString *nowplayingURL = [respArray objectAtIndex: 2];
	NSString *submissionURL = [respArray objectAtIndex: 3];
	NSLog(@"session: %@",sessionID);
	
	
	/////// mass
	
	ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString: submissionURL]]; // log in & get cookies
	[request setPostValue: sessionID forKey: @"s"];
	
	NSInteger index = 0;
	for (NSDictionary *dict in dictsToSubmit)
	{
		NSNumber *n3 = [NSNumber numberWithInt: [[dict objectForKey: @"trackPlaybackStartTime"] timeIntervalSince1970]];  //[NSNumber numberWithInt: ([n intValue] - 100)];
		
		[request setPostValue: [dict objectForKey: @"artistName"] forKey: [NSString stringWithFormat: @"a[%i]",index]];
		[request setPostValue: [dict objectForKey: @"trackName"] forKey: [NSString stringWithFormat: @"t[%i]", index]];
		[request setPostValue: n3 forKey: [NSString stringWithFormat: @"i[%i]", index]];
		[request setPostValue: @"P" forKey: [NSString stringWithFormat: @"o[%i]", index]];
		[request setPostValue: @"" forKey: [NSString stringWithFormat: @"r[%i]", index]];
		[request setPostValue: [NSString stringWithFormat: @"%i",[[dict objectForKey: @"trackLength"] intValue]] forKey: [NSString stringWithFormat: @"l[%i]", index]];
		[request setPostValue: [dict objectForKey: @"albumName"] forKey: [NSString stringWithFormat: @"b[%i]", index]];
		[request setPostValue: @"" forKey: [NSString stringWithFormat: @"n[%i]", index]];
		[request setPostValue: @"" forKey: [NSString stringWithFormat: @"m[%i]", index]];
		
		
		index ++;
	}
	[request startSynchronous];
	
	NSLog(@"scrobble submussion of %i tracks returned: %@",index,[request responseString]);
	
	if (![request responseString] || [[request responseString] length] <= 0)
	{
		NSLog(@"submission request failed.");
		[delegate performSelectorOnMainThread:@selector(lastFmScrobblerSubmissionDidFail:) withObject: self waitUntilDone: YES];
		[request release];
		[thePool release];
		return;
	}

	[delegate performSelectorOnMainThread:@selector(lastFmScrobblerSubmissionDidSucceed:) withObject: self waitUntilDone: YES];
	//[delegate lastFMScrobbler: self submissionDidSucceed: YES];
	
	NSLog(@"Last FM Submission Operation ended ...");
	[request release];
	[thePool release];	
}

- (void) dealloc
{
	NSLog(@"Last FM Submission Operation dealloc!");
	
	[self setDictsToSubmit: nil];

	[super dealloc];
}
	

@end
