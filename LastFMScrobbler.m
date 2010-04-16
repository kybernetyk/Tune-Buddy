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
	NSLog(@"notify!");
	FMEngine *fmEngine = [[FMEngine alloc] init];
	
	
	NSString *authToken = [fmEngine generateAuthTokenFromUsername: [self username] password: [self password]];
	NSDictionary *urlDict = [NSDictionary dictionaryWithObjectsAndKeys:@"arielblumenthal", @"username", authToken, @"authToken", _LASTFM_API_KEY_, @"api_key", nil, nil];
	//[fmEngine performMethod:@"auth.getMobileSession" withTarget:self withParameters:urlDict andAction:@selector(loginCallback:data:) useSignature:YES httpMethod:POST_TYPE];
	
	NSString *authURL = [NSString stringWithFormat: @"%@?format=json",_LASTFM_BASEURL_];
	NSLog(@"%@",authURL);
	

	//authenticate
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
	NSLog(@"auth response: %@", str);
	
	//timestamp lol
	NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
	NSNumber *n = [NSNumber numberWithDouble: interval];
	NSNumber *n2 = [NSNumber numberWithInt: [n intValue]];
	NSNumber *n3 = [NSNumber numberWithInt: [[self trackPlaybackStartTime] timeIntervalSince1970]];  //[NSNumber numberWithInt: ([n intValue] - 100)];
	authToken = [fmEngine scrobbleAuthToken: n2];
	[fmEngine release];
	
	
	//handshake lol
	//TODO: Parse the data (json) for session key ("0ed ...")
	NSString *urlstring = [NSString stringWithFormat: @"http://post.audioscrobbler.com/?hs=true&p=1.2.1&c=tst&v=1.0&u=arielblumenthal&t=%@&a=%@&api_key=%@&sk=%@",n2 ,authToken,_LASTFM_API_KEY_,@"0edd5a36e389998338bae96d2329db07"];
	
	NSLog(@"urlstring: %@", urlstring);
	NSString *resp = [NSString stringWithContentsOfURL: [NSURL URLWithString: urlstring]];
	
	NSLog(@"resp: %@",resp);
	
	NSArray *respArray = [resp componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
	
	//if resparray[0] != OK ... error 
	NSString *sessionID = [respArray objectAtIndex: 1];
	NSString *nowplayingURL = [respArray objectAtIndex: 2];
	NSString *submissionURL = [respArray objectAtIndex: 3];
	NSLog(@"session: %@",sessionID);
	
	NSLog(@"time: %@",n3);
	
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString: nowplayingURL]]; // log in & get cookies
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
	
	[delegate lastFMScrobbler: self submissionDidSucceed: YES];
}

- (void) performSubmission
{
	FMEngine *fmEngine = [[FMEngine alloc] init];
	
	
	NSString *authToken = [fmEngine generateAuthTokenFromUsername: [self username] password: [self password]];
	NSDictionary *urlDict = [NSDictionary dictionaryWithObjectsAndKeys:@"arielblumenthal", @"username", authToken, @"authToken", _LASTFM_API_KEY_, @"api_key", nil, nil];
	//[fmEngine performMethod:@"auth.getMobileSession" withTarget:self withParameters:urlDict andAction:@selector(loginCallback:data:) useSignature:YES httpMethod:POST_TYPE];

	NSString *authURL = [NSString stringWithFormat: @"%@?format=json",_LASTFM_BASEURL_];
	NSLog(@"%@",authURL);
	
//	generateSignatureFromDictionary
	
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

	NSLog(@"auth response: %@", str);

	
	// data is either NSData or NSError
	
	//0edd5a36e389998338bae96d2329db07
	//	NSDictionary *urlDict = [NSDictionary dictionaryWithObjectsAndKeys:@"arielblumenthal", @"username", authToken, @"authToken", _LASTFM_API_KEY_, @"api_key", nil, nil];
	
	//http://post.audioscrobbler.com/?hs=true&p=1.2.1&c=<client-id>&v=<client-ver>
	//	&u=<user>&t=<timestamp>&a=<auth>
	
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

- (void) dealloc
{
	//[fmEngine release];
	//NSLog(@"%i",[fmEngine retainCount]);
	
	NSLog(@"bye scrobbler!");
	
	[super dealloc];
}
	


@end
