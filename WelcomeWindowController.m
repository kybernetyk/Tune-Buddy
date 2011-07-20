//
//  WelcomeWindowController.m
//  Tune Buddy
//
//  Created by jrk on 20/7/11.
//  Copyright 2011 Flux Forge. All rights reserved.
//

#import "WelcomeWindowController.h"


@implementation WelcomeWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
//	NSString *address =  @"welcome/index.html";
	
//	NSLog(@"fetching token from: %@", address);
//	[bottomView addSubview: [[NSImage imageNamed: @"welcome_bottom"] view]]; 
	NSURL *url = [[NSBundle mainBundle] URLForResource:@"index" withExtension:@"html" subdirectory: @"welcome"];
	
//	NSURL *url = [NSURL URLWithString:address];
	//[[NSWorkspace sharedWorkspace] openURL:url];
	
	NSLog(@"URL: %@", url);
	
	
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL: url]];
		
	url = [[NSBundle mainBundle] URLForResource:@"bottom" withExtension:@"html" subdirectory: @"welcome"];
	[[bottomWebView mainFrame] loadRequest:[NSURLRequest requestWithURL: url]];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
