//
//  LastFMAuth.m
//  Tune Buddy
//
//  Created by jrk on 17/5/10.
//  Copyright 2010 Flux Forge. All rights reserved.
//

#import "LastFMAuth.h"
#import "FMEngine.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "JSON.h"
#import "EMKeychainItem.h"

@implementation LastFMAuth
static LastFMAuth *sharedSingleton = nil;



+(LastFMAuth*) sharedLastFMAuth 
{
    @synchronized(self) 
	{
        if (sharedSingleton == nil) 
		{
            [[self alloc] init]; // assignment not done here
        }
    }
    return sharedSingleton;
}


+(id)allocWithZone:(NSZone *)zone 
{
    @synchronized(self) 
	{
        if (sharedSingleton == nil) 
		{
            sharedSingleton = [super allocWithZone:zone];
            return sharedSingleton;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}


-(void)dealloc 
{
    [super dealloc];
}

-(id)copyWithZone:(NSZone *)zone 
{
    return self;
}


-(id)retain 
{
    return self;
}


-(NSUInteger)retainCount 
{
    return UINT_MAX;  //denotes an object that cannot be release
}


-(void)release 
{
    //do nothing    
}


-(id)autorelease 
{
    return self;    
}


-(id)init 
{
    self = [super init];
    sharedSingleton = self;
	
	[self reset];
	
    return self;
}

- (void) reset
{
	
	[_secretKey release];
	_secretKey = nil;
}


#pragma mark -
#pragma mark auth LastFM
- (NSDictionary *) lastFMCredentials
{
	NSString *user = [self username];
	NSString *pass = nil;

	EMGenericKeychainItem *keychainItem = [EMGenericKeychainItem genericKeychainItemForService: KEYCHAIN_LASTFM withUsername: user];
	if (keychainItem)
	{
		pass = [keychainItem password];
		NSLog(@"lfm pass: %@", pass);
	}
	else
	{
		NSLog(@"No lastfm credentials found!");
		return nil;
	}
	
	
	
	
	if (!user || [user length] <= 0 || [user isEqualToString: @""])
	{
		NSLog(@"no valid lastfm username found!");
		return nil;
	}
	
	if (!pass || [pass length] <= 0 || [pass isEqualToString: @""])
	{
		NSLog(@"no valid lastfm password found!");
		return nil;
	}
	
	
	return [NSDictionary dictionaryWithObjectsAndKeys: [NSString stringWithString: user], @"username", [NSString stringWithString: pass], @"password", nil];
}



- (NSString *) username
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *user = [defaults objectForKey: @"lastFMUsername"];

	if (!user)
		return nil;
	
	NSString *ret = [[NSString alloc] initWithString: [NSString stringWithString: user]];
	
	return [ret autorelease];
}

- (NSString *) password
{
	NSString *ret = [[self lastFMCredentials] objectForKey: @"password"];
	if (!ret)
		return nil;

	ret = [[NSString alloc] initWithString: [NSString stringWithString: ret]];
	return [ret autorelease];
}

#pragma mark -
#pragma mark credentials
- (NSString *) secretKey
{
	@synchronized (self)
	{
		if (_secretKey)
			return _secretKey;
		
	}

	NSString *username = [self username];
	NSString *password = [self password];
	
	if (!username || !password)
	{
		NSLog(@"no lastfm credentials set!");
		return nil;
	}
		
	FMEngine *fmEngine = [[FMEngine alloc] init];
	NSString *authToken = [fmEngine generateAuthTokenFromUsername: username password: password];
//	NSDictionary *urlDict = [NSDictionary dictionaryWithObjectsAndKeys: username, @"username", authToken, @"authToken", _LASTFM_API_KEY_, @"api_key", nil, nil];
	NSString *authURL = [NSString stringWithFormat: @"%@?format=json",_LASTFM_BASEURL_];
	
	
	ASIFormDataRequest *authReq = [[ASIFormDataRequest alloc] initWithURL: [NSURL URLWithString: authURL]];
	
	//[ASIFormDataRequest requestWithURL:[NSURL URLWithString: authURL]];
	[authReq setPostValue: @"auth.getMobileSession" forKey: @"method"];
	[authReq setPostValue: username forKey: @"username"];
	[authReq setPostValue: authToken forKey: @"authToken"];
	[authReq setPostValue: _LASTFM_API_KEY_ forKey: @"api_key"];
	
	
	NSString *sig = [fmEngine generateSignatureFromDictionary: [authReq postData]];
	
	[authReq setPostValue:sig forKey: @"api_sig"];
	[authReq setPostValue:@"json" forKey:@"format"];
	
	[authReq startSynchronous];
	
	NSString *str  = nil;
	if ([authReq responseString])
		str = [NSString stringWithString: [authReq responseString]];
	
	[authReq release];
	
	if (!str || [str length] <= 0)
	{	
		NSLog(@"auth response[==nil] failure");
		[fmEngine release];
		
		return nil;
	}
	
	NSLog(@"auth response: %@", str);
	
	SBJSON *json = [[[SBJSON alloc] init] autorelease];
	
	NSDictionary *authDict = [json objectWithString: str];
	
	NSString *secretKey = [[authDict objectForKey: @"session"] objectForKey: @"key"];
	if (!secretKey)
	{
		NSLog(@"auth did not get us a key!");
		[fmEngine release];
		return nil;
	}

	[fmEngine release];
	
	@synchronized (self)
	{
		_secretKey = [[NSString alloc] initWithString: secretKey];
	}

	return _secretKey;
	
}

@end
