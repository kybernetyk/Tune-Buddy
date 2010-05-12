//
//  LastFMScrobbler.m
//  Tune Buddy
//
//  Created by jrk on 15/4/10.
//  Copyright 2010 Flux Forge. All rights reserved.
//

#import "LastFMScrobbler.h"
#import "FMEngine.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "JSON.h"

@implementation LastFMScrobbler
@synthesize delegate;

@synthesize username;
@synthesize password;

@synthesize artistName;
@synthesize trackName;
@synthesize albumName;
@synthesize trackLength;
@synthesize trackPlaybackStartTime;

- (void) performNotification
{
//	NSLog(@"notify!");
	FMEngine *fmEngine = [[FMEngine alloc] init];
	
	
	NSString *authToken = [fmEngine generateAuthTokenFromUsername: [self username] password: [self password]];
	NSDictionary *urlDict = [NSDictionary dictionaryWithObjectsAndKeys:[self username], @"username", authToken, @"authToken", _LASTFM_API_KEY_, @"api_key", nil, nil];
	//[fmEngine performMethod:@"auth.getMobileSession" withTarget:self withParameters:urlDict andAction:@selector(loginCallback:data:) useSignature:YES httpMethod:POST_TYPE];
	
	NSString *authURL = [NSString stringWithFormat: @"%@?format=json",_LASTFM_BASEURL_];
//	NSLog(@"%@",authURL);
	

	//authenticate
	ASIFormDataRequest *authReq = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString: authURL]];
	[authReq setPostValue: @"auth.getMobileSession" forKey: @"method"];
	[authReq setPostValue: [self username] forKey: @"username"];
	[authReq setPostValue: authToken forKey: @"authToken"];
	[authReq setPostValue: _LASTFM_API_KEY_ forKey: @"api_key"];
	NSString *sig = [fmEngine generateSignatureFromDictionary: [authReq postData]];
	[authReq setPostValue:sig forKey: @"api_sig"];
	[authReq setPostValue:@"json" forKey:@"format"];
	[authReq startSynchronous];
	NSString *str  = [NSString stringWithString: [authReq responseString]];
	if (!str)
	{	
		[delegate lastFMScrobbler: self notificationDidSucceed: NO];
		NSLog(@"%@",[[authReq error] localizedDescription]);
		[authReq release];
		return;
	}
	
	[authReq release];
	
	SBJSON *json = [[[SBJSON alloc] init] autorelease];
	
	NSDictionary *authDict = [json objectWithString: str];
	
	NSString *secretKey = [[authDict objectForKey: @"session"] objectForKey: @"key"];
	if (!secretKey)
	{
		NSLog(@"auth did not get us a key!");
		[delegate performSelectorOnMainThread:@selector(lastFmScrobblerSubmissionDidFail:) withObject: self waitUntilDone: YES];
		return;
	}
	
	NSLog(@"secret key: %@", secretKey);
	
//	NSLog(@"auth response: %@", str);
	
	//timestamp lol
	NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
	NSNumber *n = [NSNumber numberWithDouble: interval];
	NSNumber *n2 = [NSNumber numberWithInt: [n intValue]];
	NSNumber *n3 = [NSNumber numberWithInt: [[self trackPlaybackStartTime] timeIntervalSince1970]];  //[NSNumber numberWithInt: ([n intValue] - 100)];
	authToken = [fmEngine scrobbleAuthToken: n2];
	[fmEngine release];
	
	
	//handshake lol
	//TODO: Parse the data (json) for session key ("0ed ...")
	NSString *urlstring = [NSString stringWithFormat: @"http://post.audioscrobbler.com/?hs=true&p=1.2.1&c=tnb&v=1.0&u=%@&t=%@&a=%@&api_key=%@&sk=%@",[self username],n2 ,authToken,_LASTFM_API_KEY_, secretKey];
	
//	NSLog(@"urlstring: %@", urlstring);
	NSString *resp = [NSString stringWithContentsOfURL: [NSURL URLWithString: urlstring]];
	if (!resp)
	{	
		[delegate lastFMScrobbler: self notificationDidSucceed: NO];
		return;
	}
	
//	NSLog(@"resp: %@",resp);
	
	NSArray *respArray = [resp componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
	
	//if resparray[0] != OK ... error 
	NSString *sessionID = [NSString stringWithString: [respArray objectAtIndex: 1]];
	NSString *nowplayingURL = [NSString stringWithString: [respArray objectAtIndex: 2]];
//	NSLog(@"session: %@",sessionID);
	
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
	[delegate lastFMScrobbler: self notificationDidSucceed: YES];
}
/*
- (void) performSubmission
{
	FMEngine *fmEngine = [[FMEngine alloc] init];
	NSString *authToken = [fmEngine generateAuthTokenFromUsername: [self username] password: [self password]];
	NSDictionary *urlDict = [NSDictionary dictionaryWithObjectsAndKeys:@"arielblumenthal", @"username", authToken, @"authToken", _LASTFM_API_KEY_, @"api_key", nil, nil];
	NSString *authURL = [NSString stringWithFormat: @"%@?format=json",_LASTFM_BASEURL_];
	NSLog(@"%@",authURL);
	
	
	ASIFormDataRequest *authReq = [ASIFormDataRequest requestWithURL:[NSURL URLWithString: authURL]];
	[authReq setPostValue: @"auth.getMobileSession" forKey: @"method"];
	[authReq setPostValue: [self username] forKey: @"username"];
	[authReq setPostValue: authToken forKey: @"authToken"];
	[authReq setPostValue: _LASTFM_API_KEY_ forKey: @"api_key"];
	
	
	NSString *sig = [fmEngine generateSignatureFromDictionary: [authReq postData]];

	[authReq setPostValue:sig forKey: @"api_sig"];
	[authReq setPostValue:@"json" forKey:@"format"];

	
	[authReq startSynchronous];
	
	NSString *str  = [authReq responseString];
	if (!str)
	{	
		[delegate lastFMScrobbler: self submissionDidSucceed: NO];
		NSLog(@"%@",[[authReq error] localizedDescription]);
		return;
		
	}
	
	NSLog(@"auth response: %@", str);

	//timestamp lol
	NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
	NSNumber *n = [NSNumber numberWithDouble: interval];
	NSNumber *n2 = [NSNumber numberWithInt: [n intValue]];
	NSNumber *n3 = [NSNumber numberWithInt: [[self trackPlaybackStartTime] timeIntervalSince1970]];  //[NSNumber numberWithInt: ([n intValue] - 100)];
	authToken = [fmEngine scrobbleAuthToken: n2];
	
	[fmEngine release];
	
	NSLog(@"date: %@", [NSDate date]);
	
	//handshake lol
	//TODO: Parse the data (json) for session key ("0ed ...")
	NSString *urlstring = [NSString stringWithFormat: @"http://post.audioscrobbler.com/?hs=true&p=1.2.1&c=tst&v=1.0&u=arielblumenthal&t=%@&a=%@&api_key=%@&sk=%@",n2 ,authToken,_LASTFM_API_KEY_,@"0edd5a36e389998338bae96d2329db07"];
	
	NSLog(@"urlstring: %@", urlstring);
	NSString *resp = [NSString stringWithContentsOfURL: [NSURL URLWithString: urlstring]];
	if (!resp)
	{	
		[delegate lastFMScrobbler: self submissionDidSucceed: NO];
		return;
		
	}
	
	NSLog(@"resp: %@",resp);
	
	NSArray *respArray = [resp componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
	
	//if resparray[0] != OK ... error 
	NSString *sessionID = [respArray objectAtIndex: 1];
	NSString *nowplayingURL = [respArray objectAtIndex: 2];
	NSString *submissionURL = [respArray objectAtIndex: 3];
	NSLog(@"session: %@",sessionID);
	
	NSLog(@"time: %@",n3);

	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString: submissionURL]]; // log in & get cookies
	
	[request setPostValue: sessionID forKey: @"s"];
	[request setPostValue: [self artistName] forKey: @"a[0]"];
	[request setPostValue: [self trackName] forKey: @"t[0]"];
	[request setPostValue: n3 forKey: @"i[0]"];
	[request setPostValue: @"P" forKey: @"o[0]"];
	[request setPostValue: @"" forKey: @"r[0]"];
	[request setPostValue: [NSString stringWithFormat: @"%i",[[self trackLength] intValue]] forKey: @"l[0]"];
	[request setPostValue: [self albumName] forKey: @"b[0]"];
	[request setPostValue: @"" forKey: @"n[0]"];
	[request setPostValue: @"" forKey: @"m[0]"];
	

	
	[request startSynchronous];
	
	
	
	
	NSLog(@"scrobble submussion returned: %@",[request responseString]);
	
	
	//[delegate performSelectorOnMainThread:@selector(lastFmScrobblerSubmissionDidSucceed:) withObject: self waitUntilDone: YES];
	[delegate lastFMScrobbler: self submissionDidSucceed: YES];
}

*/
- (void) performMassSubmissionWithArray: (NSArray *) dictsToSubmit
{
	NSLog(@"performing mass scrobble with %i songs ...", [dictsToSubmit count]);
	if ([dictsToSubmit count] <= 0)
	{
		[delegate lastFMScrobbler: self submissionDidSucceed: NO];
		return;
	}
	
	FMEngine *fmEngine = [[FMEngine alloc] init];
	NSString *authToken = [fmEngine generateAuthTokenFromUsername: [self username] password: [self password]];
	NSDictionary *urlDict = [NSDictionary dictionaryWithObjectsAndKeys:@"arielblumenthal", @"username", authToken, @"authToken", _LASTFM_API_KEY_, @"api_key", nil, nil];
	NSString *authURL = [NSString stringWithFormat: @"%@?format=json",_LASTFM_BASEURL_];

	
	
	ASIFormDataRequest *authReq = [ASIFormDataRequest requestWithURL:[NSURL URLWithString: authURL]];
	[authReq setPostValue: @"auth.getMobileSession" forKey: @"method"];
	[authReq setPostValue: [self username] forKey: @"username"];
	[authReq setPostValue: authToken forKey: @"authToken"];
	[authReq setPostValue: _LASTFM_API_KEY_ forKey: @"api_key"];
	
	
	NSString *sig = [fmEngine generateSignatureFromDictionary: [authReq postData]];
	
	[authReq setPostValue:sig forKey: @"api_sig"];
	[authReq setPostValue:@"json" forKey:@"format"];
	
	
	[authReq startSynchronous];
	
	NSString *str  = [authReq responseString];
	if (!str || [str length] <= 0)
	{	
		NSLog(@"auth response failure");
		[delegate lastFMScrobbler: self submissionDidSucceed: NO];
		NSLog(@"%@",[[authReq error] localizedDescription]);
		return;
		
	}
	
	NSLog(@"auth response: %@", str);
	
	//timestamp lol
	NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
	NSNumber *n = [NSNumber numberWithDouble: interval];
	NSNumber *n2 = [NSNumber numberWithInt: [n intValue]];
//	NSNumber *n3 = [NSNumber numberWithInt: [[self trackPlaybackStartTime] timeIntervalSince1970]];  //[NSNumber numberWithInt: ([n intValue] - 100)];
	authToken = [fmEngine scrobbleAuthToken: n2];
	
	[fmEngine release];
	
	NSLog(@"date: %@", [NSDate date]);
	
	//handshake lol
	//TODO: Parse the data (json) for session key ("0ed ...")
	NSString *urlstring = [NSString stringWithFormat: @"http://post.audioscrobbler.com/?hs=true&p=1.2.1&c=tnb&v=1.0&u=arielblumenthal&t=%@&a=%@&api_key=%@&sk=%@",n2 ,authToken,_LASTFM_API_KEY_,@"0edd5a36e389998338bae96d2329db07"];
	
	NSLog(@"urlstring: %@", urlstring);
	NSString *resp = [NSString stringWithContentsOfURL: [NSURL URLWithString: urlstring]];
	if (!resp)
	{	
		NSLog(@"no response from handshake.");
		[delegate lastFMScrobbler: self submissionDidSucceed: NO];
		return;
		
	}
	
	NSLog(@"resp: %@",resp);
	
	NSArray *respArray = [resp componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
	
	//if resparray[0] != OK ... error 
	NSString *sessionID = [respArray objectAtIndex: 1];
	NSString *nowplayingURL = [respArray objectAtIndex: 2];
	NSString *submissionURL = [respArray objectAtIndex: 3];
	NSLog(@"session: %@",sessionID);
	
	
	/////// mass
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString: submissionURL]]; // log in & get cookies
	[request setPostValue: sessionID forKey: @"s"];
	
	NSInteger index = 0;
	for (NSDictionary *dict in dictsToSubmit)
	{
		/*	[scrobbler setUsername: @"arielblumenthal"];
		 [scrobbler setPassword: @"warbird"];
		 
		 [scrobbler setArtistName: [infoDict objectForKey: @"artistName"]];
		 [scrobbler setTrackName: [infoDict objectForKey: @"trackName"]];
		 [scrobbler setAlbumName: [infoDict objectForKey: @"albumName"]];
		 [scrobbler setTrackLength: [infoDict objectForKey: @"trackLength"]];
		 [scrobbler setTrackPlaybackStartTime: [infoDict objectForKey: @"trackPlaybackStartTime"]];
*/		 
		
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
		[delegate lastFMScrobbler: self submissionDidSucceed: NO];		
		return;
	}
	//[delegate performSelectorOnMainThread:@selector(lastFmScrobblerSubmissionDidSucceed:) withObject: self waitUntilDone: YES];
	[delegate lastFMScrobbler: self submissionDidSucceed: YES];
	
}


- (void) dealloc
{
	//[fmEngine release];
	//NSLog(@"%i",[fmEngine retainCount]);
	
	NSLog(@"bye scrobbler!");
	

	[self setUsername: nil];
	[self setPassword: nil];
	[self setArtistName: nil];
	[self setTrackName: nil];
	[self setAlbumName: nil];
	[self setTrackLength: nil];
	[self setTrackPlaybackStartTime: nil];
	
	[super dealloc];
}
	


@end
