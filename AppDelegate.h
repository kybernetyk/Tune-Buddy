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
	BOOL isRegistered;
	BOOL isExpired;
	
	SS_PrefsController *preferencesWindowController;
	
	MGTwitterEngine *twitterEngine;
	NSString *lastConnectionIdentifier;
	
	IBOutlet SUUpdater *sparkle;
	
	NSStatusItem *statusItem;
	NSMenuItem *copyToClipboardMenuItem;
	NSMenuItem *preferencesMenuItem;
	NSMenuItem *smallScreenMenuSeperator;
	NSMenuItem *adiumMenuItem;
	NSMenuItem *twitterMenuItem;
	NSMenuItem *facebookMenuItem;
	NSMenuItem *smallScreenModeMenuItem;
	NSMenuItem *quitMenuItem;
	NSMenu *statusBarMenu;
	
	AdiumApplication *adium;
	
	NSString *longDisplayString;
	NSString *playStatus;
	
	NSOperationQueue *backgroundOperationQueue;
	
	BOOL smallScreenModeEnabled;
	
	BOOL growlAvailable;

	NSTimer *lastFMSubmitTimer;
	NSMutableArray *scrobbleQueue;
	
	NSImage *albumArt;
	
	NSString *trackArtist;
	NSString *trackName;
	NSString *albumName;
	NSNumber *trackRating;
	NSNumber *trackPlayCount;
	
	NSInteger facebookAuthFailCount;
}

#pragma mark -
#pragma mark properties
@property (readwrite, copy) NSNumber *trackPlayCount;

@property (readwrite, retain) NSString *playStatus;
@property (readonly, assign) BOOL isRegistered;
@property (readwrite, assign, getter=isExpired) BOOL isExpired;
@property (readwrite, copy) NSString *longDisplayString;

@property (readwrite, copy) NSImage *albumArt;

@property (readwrite, copy) NSString *trackArtist;
@property (readwrite, copy) NSString *trackName;
@property (readwrite, copy) NSString *albumName;

@property (readwrite, copy) NSNumber *trackRating;

#pragma mark -
#pragma mark public IB accessable methods
- (IBAction) openPreferencesWindow: (id) sender;
- (IBAction) quitAppByMenu : (id) sender;
- (IBAction) copyCurrentTrackInfoToClipBoard: (id) sender;
- (IBAction) sendCurrentTrackToAdium: (id) sender;
- (IBAction) sendCurrentTrackToTwitter: (id) sender;
- (IBAction) sendCurrentTrackToFacebook: (id) sender;

- (void) createStatusItem;

#pragma mark -
#pragma mark private methods
- (NSString *) displayString;

#pragma mark -
#pragma mark Application Delegate Methods
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;

- (void) checkRegistration;

@end
