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

@implementation FacebookShareOperation
@synthesize delegate;
@synthesize message;

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
	NSLog(@"share op dealloc!");
	[super dealloc];
}

- (void) main
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSLog(@"sending to fb ...");
	
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	NSString *token = [[defs objectForKey: @"facebookAccessToken"] URLEncodedString];
	if (!token)
	{
		NSLog(@"no token found. please auth!");
		[self messageDelegateFailure];
		[pool drain];
		return;
	}
	
	NSString *messageText = [[self message] URLEncodedString];
	
	
	NSString *actionLinks = [@"[{\"text\":\"Tune Buddy for Mac\",\"href\":\"http://www.fluxforge.com/tune-buddy/\"}]" URLEncodedString];
	
	NSString *callURL = [NSString stringWithFormat: @"https://api.facebook.com/method/stream.publish?message=%@&access_token=%@&action_links=%@",
						 messageText,
						 token,
						 actionLinks];
	NSURL *url = [NSURL URLWithString: callURL];
	NSString *ret = [NSString stringWithContentsOfURL: url];
	NSLog(@"fb ret: %@", ret);	
	
	//Invalid OAuth 2.0 Access Token
	
	if ([ret containsString: @"error_response" ignoringCase: YES])
	{
		[defs removeObjectForKey: @"facebookAccessToken"];

		[self messageDelegateFailure];
		[pool drain];
		return;
	}
	
	[self messageDelegateSuccess];
	[pool drain];
	return;
}

@end
