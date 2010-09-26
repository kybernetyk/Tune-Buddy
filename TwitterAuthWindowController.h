//
//  TwitterAuthWindowController.h
//  Tune Buddy
//
//  Created by jrk on 2/9/10.
//  Copyright 2010 Flux Forge. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "OAuthConsumer.h"

@interface TwitterAuthWindowController : NSWindowController 
{
	IBOutlet WebView *webView;

	OAToken *accessToken;
	
	NSUInteger loadcount;
	
	
	id delegate;
}

@property (readwrite, assign) id delegate;

@end
