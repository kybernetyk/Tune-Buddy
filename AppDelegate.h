//
//  AppDelegate.h
//  itunes control
//
//  Created by Jaroslaw Szpilewski on 07.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Sparkle/Sparkle.h>
#import "iTunes.h"
#import "Adium.h"
#import "MGTwitterEngine.h"
#import "SS_PrefsController.h"

@interface AppDelegate : NSObject 
{
	NSStatusItem *statusItem;
	
	BOOL isRegistered;
	SS_PrefsController *preferencesWindowController;
	
	MGTwitterEngine *twitterEngine;
	NSString *lastConnectionIdentifier;
	
	IBOutlet SUUpdater *sparkle;
	
	NSMenuItem *adiumMenuItem;
	NSMenuItem *twitterMenuItem;
	
	AdiumApplication *adium;
	
	NSString *longDisplayString;
	
	NSOperationQueue *backgroundOperationQueue;
}

@property (readonly, assign) BOOL isRegistered;
@property (readwrite, copy) NSString *longDisplayString;

#pragma mark -
#pragma mark public IB accessable methods
- (IBAction) startPolling: (id) sender;
- (IBAction) stopPolling: (id) sender;
- (IBAction) openRegistrationWindow: (id) sender;
- (IBAction) openPreferencesWindow: (id) sender;
- (IBAction) quitAppByMenu : (id) sender;
- (IBAction) copyCurrentTrackInfoToClipBoard: (id) sender;
- (IBAction) sendCurrentTrackToAdium: (id) sender;
- (IBAction) sendCurrentTrackToTwitter: (id) sender;


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
