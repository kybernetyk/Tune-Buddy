//
//  AppDelegate.h
//  itunes control
//
//  Created by Jaroslaw Szpilewski on 07.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RegistrationWindowController.h"
#import <Sparkle/Sparkle.h>
#import "iTunes.h"
#import "Adium.h"

@interface AppDelegate : NSObject 
{
	NSStatusItem *statusItem;
	
	BOOL isRegistered;
	RegistrationWindowController *registrationWindowController;
	
	IBOutlet SUUpdater *sparkle;
	
	NSMenuItem *adiumMenuItem;
	
	iTunesApplication *iTunes;
	AdiumApplication *adium;
}

@property (readonly, assign) BOOL isRegistered;

#pragma mark -
#pragma mark public IB accessable methods
- (IBAction) startPolling: (id) sender;
- (IBAction) stopPolling: (id) sender;
- (IBAction) openRegistrationWindow: (id) sender;
- (IBAction) quitAppByMenu : (id) sender;


#pragma mark -
#pragma mark private methods
- (NSString *) displayString;
- (void) createStatusItemWithTitle: (NSString *) title;
- (void) handlePollTimer: (NSTimer *) timer;
//- (void) processCommandString: (NSString *) commandString;

#pragma mark -
#pragma mark Application Delegate Methods
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;

- (void) checkRegistration;

@end
