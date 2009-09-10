//
//  AppDelegate.h
//  itunes control
//
//  Created by Jaroslaw Szpilewski on 07.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AppDelegate : NSObject 
{
	BOOL isMuted;
	int previousVolume;
	
	NSTimer *pollTimer;
	BOOL isPolling;
	
	NSStatusItem *statusItem;
}

#pragma mark -
#pragma mark iTunes Controll Methods
- (void) toggleMute;
- (void) increaseVolume;
- (void) decreaseVolume;
- (void) startPlayback;
- (void) stopPlayback;
- (void) pausePlayback;
- (void) nextTrack;
- (void) previousTrack;

#pragma mark -
#pragma mark public IB accessable methods
- (IBAction) startPolling: (id) sender;
- (IBAction) stopPolling: (id) sender;
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


@end
