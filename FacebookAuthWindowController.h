//
//  FacebookAuthWindowController.h
//  Tune Buddy
//
//  Created by jrk on 26/9/10.
//  Copyright 2010 Flux Forge. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>


@interface FacebookAuthWindowController : NSWindowController 
{
	IBOutlet WebView *webView;
	
	NSString *authToken;
	
	id delegate;
}

@property (readwrite, assign) id delegate;

- (void) fetchAuthToken;
- (void) fetchAccessToken;

@end
