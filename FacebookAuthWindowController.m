//
//  FacebookAuthWindowController.m
//  Tune Buddy
//
//  Created by jrk on 26/9/10.
//  Copyright 2010 Flux Forge. All rights reserved.
//

#import "FacebookAuthWindowController.h"
#import "NSString+Search.h"

@implementation FacebookAuthWindowController
@synthesize delegate;

- (void) windowDidLoad
{
	[super windowDidLoad];
	authDidSuceed = NO;
	[self fetchAuthToken];
	
}

- (void)windowWillClose:(NSNotification *)notification
{
	[webView setFrameLoadDelegate: nil];
	NSLog(@"window will close");
	
	if (!authDidSuceed)
		[delegate facebookWindowControllerDidFail];
	
	[self autorelease];
}

- (void) dealloc
{
	[webView setFrameLoadDelegate: nil];
	NSLog(@"Facebook Controller dealloc");
	[authToken release], authToken = nil;
	
	[super dealloc];
}

- (void) fetchAuthToken
{
//https://graph.facebook.com/oauth/authorize
	NSString *address = [NSString stringWithFormat:
						 @"https://graph.facebook.com/oauth/authorize?client_id=%@&redirect_uri=http://www.fluxforge.com/tune-buddy/facebook_oauth/&display=popup&scope=publish_stream,offline_access",
						FACEBOOK_API_CLIENT_ID];
	
	NSLog(@"fetching token from: %@", address);
	
	NSURL *url = [NSURL URLWithString:address];
	//[[NSWorkspace sharedWorkspace] openURL:url];
	
	NSLog(@"URL: %@", url);
	
	
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL: url]];
	
}

/*- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
	NSLog(@"did start: %@", frame);	
	NSLog(@"shit: %@", [[[frame dataSource] response] URL]);
	NSLog(@"shit2: %@", [[[frame dataSource] request] URL]);
}*/

- (void)webView:(WebView *)sender didCommitLoadForFrame:(WebFrame *)frame
{
	NSLog(@"did commit: %@", frame);
	NSLog(@"shit: %@", [[[frame dataSource] response] URL]);
	NSLog(@"shit2: %@", [[[frame dataSource] request] URL]);
	
//	NSURL *URL = [[[frame dataSource] response] URL];

	NSString *urlstring1 = [[[[frame dataSource] response] URL] absoluteString];
	NSString *urlstring2 = [[[[frame dataSource] request] URL] absoluteString];
	
	NSString *urlstring = nil;
	
	NSString *needle = [NSString stringWithFormat: @"%@", FACEBOOK_API_CALLBACK_URL];
	
	if ([urlstring1 containsString: needle ignoringCase: YES])
		urlstring = urlstring1;

	if ([urlstring2 containsString: needle ignoringCase: YES])
		urlstring = urlstring2;
	
	if (!urlstring)
		return;

		NSLog(@"will redirect to url: %@", urlstring);
	if ([urlstring containsString: needle ignoringCase: YES])
	{
		NSString *errorNeedle = @"error";
		NSString *successNeedle = @"code=";
		
		if ([urlstring containsString: errorNeedle ignoringCase: YES])
		{
			[[self window] close];
		}
		
		if ([urlstring containsString: successNeedle ignoringCase: YES])
		{
			NSRange r = [urlstring rangeOfString: successNeedle options: NSCaseInsensitiveSearch];
			if (r.location != NSNotFound)
			{
				authToken = [urlstring substringFromIndex: r.location + r.length];
				[authToken retain];
				
				NSLog(@"auth token is: %@", authToken);
				[webView stopLoading: self];
				
				[self fetchAccessToken];
			}
		}
		
	}

}
/*- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame 
{
	NSLog(@"did finish: %@", frame);
	NSLog(@"shit: %@", [[[frame dataSource] response] URL]);
	NSLog(@"shit2: %@", [[[frame dataSource] request] URL]);
}*/

- (void)webView:(WebView *)sender willPerformClientRedirectToURL:(NSURL *)URL delay:(NSTimeInterval)seconds fireDate:(NSDate *)date forFrame:(WebFrame *)frame
{
	NSLog(@"will redirect to url: %@", [URL description]);
	NSString *urlstring = [URL absoluteString];
	
	NSString *needle = [NSString stringWithFormat: @"%@", FACEBOOK_API_CALLBACK_URL];
	
	if ([urlstring containsString: needle ignoringCase: YES])
	{
		NSString *errorNeedle = @"error";
		NSString *successNeedle = @"code=";
		
		if ([urlstring containsString: errorNeedle ignoringCase: YES])
		{
			[[self window] close];
		}
		
		if ([urlstring containsString: successNeedle ignoringCase: YES])
		{
			NSRange r = [urlstring rangeOfString: successNeedle options: NSCaseInsensitiveSearch];
			if (r.location != NSNotFound)
			{
				authToken = [urlstring substringFromIndex: r.location + r.length];
				[authToken retain];
				
				NSLog(@"auth token is: %@", authToken);
				[webView stopLoading: self];
				
				[self fetchAccessToken];
			}
		}
		
	}
	
	
//	 will redirect to url: http://www.fluxforge.com/tune-buddy/facebook_oauth/?error_reason=user_denied&error=access_denied&error_description=The+user+denied+your+request.
}	

- (void) fetchAccessToken
{
	NSLog(@"fetching access token!");
	
	NSString *urlString = [NSString stringWithFormat: @"https://graph.facebook.com/oauth/access_token?client_id=%@&redirect_uri=%@&client_secret=%@&code=%@",
						   FACEBOOK_API_CLIENT_ID,
						   FACEBOOK_API_CALLBACK_URL,
						   FACEBOOK_API_SECRET,
						   authToken];
	NSURL *url = [NSURL URLWithString: urlString];
	
	NSError *err;
	NSString *responseString = [NSString stringWithContentsOfURL: url encoding: NSUTF8StringEncoding error: &err];
	
	NSArray *params = [responseString componentsSeparatedByString: @"&"];
	
	NSLog(@"param array: %@", params);
	NSString *needle = @"access_token=";
	
	for (NSString *param in params)
	{
		if ([param containsString: needle ignoringCase: YES])
		{
			NSRange r = [param rangeOfString: needle options: NSCaseInsensitiveSearch];
			if (r.location != NSNotFound)
			{
				NSString *accessToken = [param substringFromIndex: r.location + r.length];
				
				NSLog(@"ACCESS TOKEN BIATCH: %@", accessToken);
				accessToken = [accessToken URLDecodedString]; //just in case FB returns a URL encoded token (they seem to do that some times) convert it back
				NSLog(@"ACCESS TOKEN BIATCH: %@", accessToken);
				
				NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
				[defs setObject: accessToken forKey: @"facebookAccessToken"];
				[defs synchronize];
				[[self window] close];
				
				[delegate facebookWindowControllerDidSucceed];
				
				return;
			}

		}
	}
	
	//fail
	[[self window] close];
}


@end
