//
//  TwitterAuthWindowController.m
//  Tune Buddy
//
//  Created by jrk on 2/9/10.
//  Copyright 2010 Flux Forge. All rights reserved.
//

#import "TwitterAuthWindowController.h"
#import "OAuthConsumer.h"
NSString *consumerKey = @"N5xET9H7GvoErKPu2bmOaQ";
NSString *consumerSecret = @"sH4lPqr7cIV2xebsDlAYmAWHd3S5Km6Q5JbtWUut80";

@implementation TwitterAuthWindowController
@synthesize delegate;

- (void) dealloc
{
	[accessToken release], accessToken = nil;
	NSLog(@"twitter dealloc");
	[super dealloc];
}

- (void) windowDidLoad
{
	[super windowDidLoad];
	loadcount = 0;

	[self getRequestToken: self];
	
}

- (void)windowWillClose:(NSNotification *)notification
{

	[self autorelease];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	loadcount ++;
	NSLog(@"webview penissed");

	if (loadcount == 2)
	{
		loadcount = 0;
		pin = [[self locateAuthPinInWebView] retain];
		if (pin)
		{
			[self getAccessToken: self];
		}
		else
		{
			[[self window] close];
		}
	}
		
	
}


- (IBAction) getRequestToken:(id)sender
{
	
	OAConsumer *consumer = [[OAConsumer alloc] initWithKey:consumerKey
													secret:consumerSecret];
	
	OADataFetcher *fetcher = [[OADataFetcher alloc] init];
	
	NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/request_token"];
	
	OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url
																   consumer:consumer
																	  token:nil
																	  realm:nil
														  signatureProvider:nil];
	
	[request setHTTPMethod:@"POST"];
	
	NSLog(@"Getting request token...");
	
	[fetcher fetchDataWithRequest:request 
						 delegate:self
				didFinishSelector:@selector(requestTokenTicket:didFinishWithData:)
				  didFailSelector:@selector(requestTokenTicket:didFailWithError:)];	
}

- (IBAction) getAccessToken:(id)sender
{
	OAConsumer *consumer = [[OAConsumer alloc] initWithKey:consumerKey
													secret:consumerSecret];
	
	OADataFetcher *fetcher = [[OADataFetcher alloc] init];
	
	NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
	
	[accessToken setVerifier: pin];
	NSLog(@"Using PIN %@", accessToken.verifier);
	
	OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url
																   consumer:consumer
																	  token:accessToken
																	  realm:nil
														  signatureProvider:nil];
	
	[request setHTTPMethod:@"POST"];
	
	NSLog(@"Getting access token...");
	
	[fetcher fetchDataWithRequest:request 
						 delegate:self
				didFinishSelector:@selector(accessTokenTicket:didFinishWithData:)
				  didFailSelector:@selector(accessTokenTicket:didFailWithError:)];	
}

- (void) requestTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data
{
	if (ticket.didSucceed)
	{
		NSString *responseBody = [[NSString alloc] initWithData:data 
													   encoding:NSUTF8StringEncoding];
		accessToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
		
		NSLog(@"Got request token. Redirecting to twitter auth page...");
		
		NSString *address = [NSString stringWithFormat:
							 @"https://api.twitter.com/oauth/authorize?oauth_token=%@",
							 accessToken.key];
		
		NSURL *url = [NSURL URLWithString:address];
		//[[NSWorkspace sharedWorkspace] openURL:url];
		
		[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL: url]];
	}
}

- (void) requestTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error
{
	NSLog(@"Getting request token failed: %@", [error localizedDescription]);
			[[self window] close];
}

- (void) accessTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data
{
	if (ticket.didSucceed)
	{
		NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		accessToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
		
		NSLog(@"Got access token. Ready to use Twitter API.");
		[accessToken storeInUserDefaultsWithServiceProviderName: @"twitter" prefix: @"fx"];
		[delegate twitterWindowControllerDidSucced];
		[[self window] close];
	}
}

- (void) accessTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error
{
	NSLog(@"Getting access token failed: %@", [error localizedDescription]);
			[[self window] close];
}


- (NSString *) locateAuthPinInWebView
{
	NSString			*js = @"var d = document.getElementById('oauth-pin'); if (d == null) d = document.getElementById('oauth_pin'); if (d) d = d.innerHTML; if (d == null) {var r = new RegExp('\\\\s[0-9]+\\\\s'); d = r.exec(document.body.innerHTML); if (d.length > 0) d = d[0];} d.replace(/^\\s*/, '').replace(/\\s*$/, ''); d;";
	NSString *_pin = [webView stringByEvaluatingJavaScriptFromString: js];
	_pin = [_pin stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (_pin.length > 0) 
		return _pin;
	
	NSString			*html = [webView stringByEvaluatingJavaScriptFromString: @"document.body.innerText"];
	
	if (html.length == 0) return nil;
	
	const char			*rawHTML = (const char *) [html UTF8String];
	int					length = strlen(rawHTML), chunkLength = 0;
	
	for (int i = 0; i < length; i++) 
	{
		if (rawHTML[i] < '0' || rawHTML[i] > '9') 
		{
			if (chunkLength == 7) 
			{
				char				*buffer = (char *) malloc(chunkLength + 1);
				
				memmove(buffer, &rawHTML[i - chunkLength], chunkLength);
				buffer[chunkLength] = 0;
				
				_pin = [NSString stringWithUTF8String: buffer];
				free(buffer);
				return _pin;
			}
			chunkLength = 0;
		} else
			chunkLength++;
	}
	
	return nil;
}

@end
