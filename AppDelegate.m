//
//  AppDelegate.m
//  itunes control
//
//  Created by Jaroslaw Szpilewski on 07.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "EyeTunes.h"

@implementation AppDelegate

#pragma mark -
#pragma mark iTunes Controll Methods

// mute/unmute
- (void) toggleMute
{
	if (isMuted == YES)
	{
		isMuted = NO;
		
		[[EyeTunes sharedInstance] setPlayerVolume: previousVolume];
		
	}
	else
	{
		isMuted = YES;
		
		previousVolume = [[EyeTunes sharedInstance] playerVolume];
		[[EyeTunes sharedInstance] setPlayerVolume: 0];
	}
}


/*
 wrapper functions for EyeTunes messages
*/
- (void) increaseVolume
{
	[[EyeTunes sharedInstance] setPlayerVolume: [[EyeTunes sharedInstance] playerVolume] + 10];
}

- (void) decreaseVolume
{
	[[EyeTunes sharedInstance] setPlayerVolume: [[EyeTunes sharedInstance] playerVolume] - 10];	
}

- (void) startPlayback
{
	[[EyeTunes sharedInstance] play];	
}

- (void) stopPlayback
{
	[[EyeTunes sharedInstance] stop];
}

- (void) pausePlayback
{
	[[EyeTunes sharedInstance] pause];
}

- (void) nextTrack
{
	[[EyeTunes sharedInstance] nextTrack];
}

-(void) previousTrack
{
	[[EyeTunes sharedInstance] previousTrack];
}



#pragma mark -
#pragma mark public IB accessable methods

// starts the poll Timer that will fetch new commands every 1.0 secs
- (IBAction) startPolling: (id) sender
{
	isMuted = NO;
	isPolling = NO;
	
	pollTimer = [NSTimer scheduledTimerWithTimeInterval: 0.1
												  target: self
												selector: @selector(handlePollTimer:)
												userInfo: nil
												repeats: YES];

	[pollTimer retain]; //timer could get autoreleased anytime
}


// stops the poll timer
- (IBAction) stopPolling: (id) sender
{
	[pollTimer invalidate];
	[pollTimer release];
}

//quits the application if chosen from the status menu 
- (IBAction) quitAppByMenu : (id) sender
{
	[NSApp terminate: self];
}


//copy the current info to clip board
- (IBAction) copyCurrentTrackInfoToClipBoard: (id) sender
{
	NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
	[pasteBoard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] owner:nil];
	[pasteBoard setString:[self displayString] forType:NSStringPboardType];
}

#pragma mark -
#pragma mark private methods


// creates a menu item in the status menu
- (void) createStatusItemWithTitle: (NSString *) title
{
	NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
	
	if (statusItem)
	{	
		[statusBar removeStatusItem: statusItem];
		[statusItem release];
	}
	
	NSMenu *menu = [[[NSMenu alloc] initWithTitle:@"menu title"] autorelease];
	
	NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:@"Preferences" action:@selector(openPreferences:) keyEquivalent:[NSString string]] autorelease];
	[menu addItem: menuItem];
	
	[menu addItemWithTitle:@"Copy To Clip Board" action:@selector(copyCurrentTrackInfoToClipBoard:) keyEquivalent: [NSString string]];
	[menu addItem:[NSMenuItem separatorItem]];
	
	[menu addItemWithTitle:@"Quit" action:@selector(quitAppByMenu:) keyEquivalent:[NSString string]];
	
	
	NSFont *font = [NSFont fontWithName:@"Verdana" size: 11.0f];
	//NSLog(@"%@",font);
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys: font,@"NSFont",nil];
	NSAttributedString *attributedTitle = [[[NSAttributedString alloc] initWithString: title attributes: attributes] autorelease];
	

	statusItem = [statusBar statusItemWithLength: NSVariableStatusItemLength];
	//[statusItem setTitle: title];
	[statusItem setAttributedTitle: attributedTitle];
	[statusItem setEnabled: YES];
	[statusItem setHighlightMode: YES];
	[statusItem setMenu: menu];
	
	[statusItem retain];
	
}

// the remote point where we can poll our messages
// make this a preference setting
#define POLL_MESSAGE_REMOTE_URL "http://localhost:8888/control/poll_message.php"


//returns the string that will be displayed/copied to pasteboard
- (NSString *) displayString
{
	NSString *playStatus = @"⌽ ";
	NSString *trackName = nil; //@"...";
	NSString *artistName = nil;// @"";
	NSString *delimiter = nil;// @"";
	
	BOOL isStream = NO;
	
	//NSLog(@"%i",[[EyeTunes sharedInstance] playerPosition]);
	ETTrack *currentTrack = [[EyeTunes sharedInstance] currentTrack];
	
	if (currentTrack)
	{
		trackName = [currentTrack name];
		artistName = [currentTrack artist];
		delimiter = @" - ";
		//NSLog(@"t: %@\na: %@\nd: %@",trackName,artistName,delimiter);	
		
		if ([trackName isEqualToString:@""])
		{	
			trackName = nil;
			delimiter = nil;
		}
		if ([artistName isEqualToString:@""])
		{	
			artistName = nil;
			delimiter = nil;
		}
		
		if (![currentTrack location])
			isStream = YES;
		
		
		if (isStream)
		{
			//stream titel!
			NSString *streamTitle = [[EyeTunes sharedInstance] getPropertyAsStringForDesc: ET_APP_CURRENT_STREAM_TITLE];
			
			//NSLog(@"%@",streamTitle);
			
			if (streamTitle && ![streamTitle isEqualToString: @""])
			{				
			//	NSLog (@"%@",[[EyeTunes sharedInstance] getPropertyAsStringForDesc: ET_APP_CURRENT_STREAM_TITLE]);
				BOOL showRadioStation = NO;
				
				if (showRadioStation)
				{
					artistName = trackName;
					trackName = streamTitle;
					delimiter = @": ";
				}
				else
				{
					artistName = streamTitle;
					trackName = nil;
					delimiter = nil;
				}
	
			}
			//no stream title
			else
			{
				NSLog(@"no stream title!");
			}
		}
		
		//radio:
		// location == nil
	}
	
	if ([[EyeTunes sharedInstance] playerState] == kETPlayerStatePlaying)
	{	
		playStatus = @"♫ ";
		
		if (isStream)
			playStatus = @"☢ ";
	}
	
	
	if (!artistName && !trackName)
	{
		return [NSString stringWithFormat:@"%@",playStatus];		
	}
	
	if (!artistName)
	{
		return [NSString stringWithFormat:@"%@%@",playStatus,trackName];
	}

	if (!trackName)
	{
		return [NSString stringWithFormat:@"%@%@",playStatus,artistName];
	}
	
	
	return [NSString stringWithFormat:@"%@%@%@%@",playStatus,artistName,delimiter,trackName];
	
}

// the timer's main loop. fetches command from server and processes it
- (void) handlePollTimer: (NSTimer *) timer
{
	//work against lag.
	//if isPolling == TRUE don't poll for new message
	if (isPolling == YES)
	{	
		NSLog(@"isPolling = YES!!!");
		return;
	}
	
	//ok, we're polling now
	isPolling = YES;


	
	if (![[statusItem title] isEqualToString: [self displayString]])
		[self createStatusItemWithTitle: [self displayString]];
	
//	[statusItem setTitle: displayString];
	
	
//	NSURL *url = [NSURL URLWithString:@POLL_MESSAGE_REMOTE_URL];
//	NSString *commandString = [NSString stringWithContentsOfURL: url];

	//[self processCommandString: commandString];

	isPolling = NO;
}

//processes the received commandString
/*- (void) processCommandString: (NSString *) commandString
{
	commandString = [commandString lowercaseString];
	
	if ([commandString isEqualToString: @"none"])
	{
		return;
	}
	
	//if (commandString)
	//	[statusItem setTitle: commandString];
	

	
	
	//don't spam log with "none" :)
	NSLog(@"chosing action for: %@",commandString);	

	if ([commandString isEqualToString: @"stop"])
	{
		[self stopPlayback];
		return;
	}

	if ([commandString isEqualToString: @"pause"])
	{
		[self pausePlayback];
		return;
	}
	
	if ([commandString isEqualToString: @"play"])
	{
		[self startPlayback];
		return;
	}
	
	if ([commandString isEqualToString: @"next"])
	{
		[self nextTrack];
		return;
	}
	
	if ([commandString isEqualToString: @"prev"])
	{
		[self previousTrack];
		return;
	}
	
	if ([commandString isEqualToString: @"vol_dec"])
	{
		[self decreaseVolume];
		return;
	}
	
	if ([commandString isEqualToString: @"vol_inc"])
	{
		[self increaseVolume];
		return;
	}
	
	if ([commandString isEqualToString: @"mute_unmute"])
	{
		[self toggleMute];
		return;
	}
	
}*/



#pragma mark -
#pragma mark Application Delegate Methods

// called by cocoa when our app is loaded and ready to run
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	//create the status menu item
	[self createStatusItemWithTitle: @"♫ ..."];
	
	//starts the poll timer that will fetch new commands every 1.0 secs
	[self startPolling: self];
	
}


@end
