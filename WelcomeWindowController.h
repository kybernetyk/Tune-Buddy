//
//  WelcomeWindowController.h
//  Tune Buddy
//
//  Created by jrk on 20/7/11.
//  Copyright 2011 Flux Forge. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>


@interface WelcomeWindowController : NSWindowController {
	IBOutlet WebView *webView;
	IBOutlet WebView *bottomWebView;
	IBOutlet NSButton *buyButton;   
	IBOutlet NSButton *checkBox;
}

-(IBAction) closeMe: (id) sender;
-(IBAction) mercantilismNow: (id) sender;
@end
