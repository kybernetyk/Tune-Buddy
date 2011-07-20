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
	NSLog(@"welcome window dealloc!");
    [super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
//	NSString *address =  @"welcome/index.html";
	
//	NSLog(@"fetching token from: %@", address);
//	[bottomView addSubview: [[NSImage imageNamed: @"welcome_bottom"] view]]; 
	
#ifdef LITE_VERSION
	NSString *subdir = @"welcome_lite";
	[buyButton setHidden: NO];
	[[self window] setTitle: @"Welcome to Tune Buddy Lite"];
	NSRect f = [[self window] frame];
	f.size.width = 960;
	[[self window] setFrame: f display: NO animate: NO];
	[[self window] center];
#else
	NSString *subdir = @"welcome";
	[[self window] setTitle: @"Welcome to Tune Buddy"];
#endif
	
	NSURL *url = [[NSBundle mainBundle] URLForResource:@"index" withExtension:@"html" subdirectory: subdir];
	
//	NSURL *url = [NSURL URLWithString:address];
	//[[NSWorkspace sharedWorkspace] openURL:url];
	
	NSLog(@"URL: %@", url);
	
	
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL: url]];
		
	url = [[NSBundle mainBundle] URLForResource:@"bottom" withExtension:@"html" subdirectory: subdir];
	[[bottomWebView mainFrame] loadRequest:[NSURLRequest requestWithURL: url]];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

-(IBAction) closeMe: (id) sender
{
	[[self window] close];
	[self autorelease];
}

-(IBAction) mercantilismNow: (id) sender
{
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://mas"]];
}
@end
