//
//  WelcomeWindowController.m
//  Tune Buddy
//
//  Created by jrk on 20/7/11.
//  Copyright 2011 Flux Forge. All rights reserved.
//

#import "WelcomeWindowController.h"
#import "AppDelegate.h"
#import "NSString+Search.h"

@interface WelcomeWindowController() 
- (void) loadTrialPromotion;
- (void) loadLitePromotion;
@end


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
	NSString *subdir = nil;

//lite MAS version
#ifdef MAS_VERSION
	#ifdef LITE_VERSION
	subdir = @"welcome_lite";
	[buyButton setHidden: NO];
	[buyButton becomeFirstResponder];
	[[self window] setTitle: @"Welcome to Tune Buddy Lite"];
	NSRect f = [[self window] frame];
	f.size.width = 960;
	[[self window] setFrame: f display: NO animate: NO];
	[[self window] center];
	[checkBox setHidden: YES];
	#else
	subdir = @"welcome";
	[[self window] setTitle: @"Welcome to Tune Buddy"];
	#endif	
#else //normal version
	if ([(AppDelegate*)[NSApp delegate] isRegistered]) {
		subdir = @"welcome";
		[[self window] setTitle: @"Welcome to Tune Buddy"];
	} else {
		subdir = @"welcome_trial";
		[[self window] setTitle: @"Welcome to Tune Buddy [Trial]"];
		
		[buyButton setHidden: NO];
		[buyButton setTitle: @"Purchase Tune Buddy"];
		[buyButton becomeFirstResponder];
		[checkBox setEnabled: NO];
		NSRect f = [[self window] frame];
		f.size.width = 960;
		[[self window] setFrame: f display: NO animate: NO];
		[[self window] center];
	}
#endif
	
	if (!subdir)
		subdir = @"welcome";
	
	NSURL *url = [[NSBundle mainBundle] URLForResource:@"index" withExtension:@"html" subdirectory: subdir];
	NSLog(@"URL: %@", url);
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL: url]];
	url = [[NSBundle mainBundle] URLForResource:@"bottom" withExtension:@"html" subdirectory: subdir];
	[[bottomWebView mainFrame] loadRequest:[NSURLRequest requestWithURL: url]];

#ifdef MAS_VERSION
	#ifdef LITE_VERSION
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
	dispatch_async(queue, ^{
		dispatch_queue_t q = dispatch_get_main_queue();
		dispatch_async(q, ^{
			NSString *prom = [NSString stringWithContentsOfURL: [NSURL URLWithString: @"http://www.fluxforge.com/tune-buddy/promo_lite.txt"]
													  encoding: NSUTF8StringEncoding
														 error: NULL];
			NSLog(@"prom: %@", prom);
			if (prom && [prom length] > 0 && [prom containsString: @"yes" ignoringCase: YES])
				[self loadLitePromotion];
			else
				NSLog(@"no promo for lite found!");
		});
	});
	#endif
#else
	if (![[NSApp delegate] isRegistered]) {
		dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
		dispatch_async(queue, ^{
			dispatch_queue_t q = dispatch_get_main_queue();
			dispatch_async(q, ^{
				NSString *prom = [NSString stringWithContentsOfURL: [NSURL URLWithString: @"http://www.fluxforge.com/tune-buddy/promo_trial.txt"]
														  encoding: NSUTF8StringEncoding
															 error: NULL];
				NSLog(@"prom: %@", prom);
				if (prom && [prom length] > 0 && [prom containsString: @"yes" ignoringCase: YES])
					[self loadTrialPromotion];
				else
					NSLog(@"no promo for trial found!");
			});
		});
	}
#endif
}

- (void) loadTrialPromotion 
{
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL: [NSURL URLWithString: @"http://www.fluxforge.com/tune-buddy/promo_trial/"]]];
}

- (void) loadLitePromotion
{
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL: [NSURL URLWithString: @"http://www.fluxforge.com/tune-buddy/promo_lite/"]]];	
}

-(IBAction) closeMe: (id) sender
{
	[[self window] close];
	[self autorelease];
}

-(IBAction) mercantilismNow: (id) sender
{
#ifdef MAS_VERSION
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"macappstore://itunes.apple.com/us/app/tune-buddy/id402489864?mt=12"]];
#else
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://www.fluxforge.com/tune-buddy/buy/"]];
#endif
}
@end
