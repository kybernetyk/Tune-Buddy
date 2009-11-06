//
//  AppDelegate.m
//  itunes control
//
//  Created by Jaroslaw Szpilewski on 07.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "iTunes.h"
#import "Adium.h"
#import "NSString+Search.h"




@implementation AppDelegate
@synthesize isRegistered;

#pragma mark -
#pragma mark public IB accessable methods

// starts the poll Timer that will fetch new commands every 1.0 secs
- (IBAction) startPolling: (id) sender
{
	[NSTimer scheduledTimerWithTimeInterval: 0.5
												  target: self
												selector: @selector(handlePollTimer:)
												userInfo: nil
												repeats: YES];

	
}

- (IBAction) checkForUpdates: (id) sender
{
	[sparkle checkForUpdates: sender];
}

// stops the poll timer
- (IBAction) stopPolling: (id) sender
{
}

//quits the application if chosen from the status menu 
- (IBAction) quitAppByMenu : (id) sender
{
	[NSApp terminate: self];
}

- (IBAction) openRegistrationWindow: (id) sender
{
	if (!registrationWindowController)
		registrationWindowController = [[RegistrationWindowController alloc] initWithWindowNibName: @"RegistrationWindow"];
	
//	NSLog(@"window: %@",[registrationWindowController window]);

	
	[[registrationWindowController window] center];
	[[registrationWindowController window] makeKeyAndOrderFront: self];

	
	[registrationWindowController updateWindowWithRegistrationInfo];
}

//copy the current info to clip board
- (IBAction) copyCurrentTrackInfoToClipBoard: (id) sender
{
	NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
	[pasteBoard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] owner:nil];
	[pasteBoard setString:[self longDisplayString] forType:NSStringPboardType];
}

- (IBAction) sendCurrentTrackToAdium: (id) sender
{
	if (!adium)
		adium = [SBApplication applicationWithBundleIdentifier:@"com.adiumX.adiumX"];
	
	if (![adium isRunning])
		return;

	AdiumChat *currentChat = [adium activeChat];
	[currentChat sendMessage: [self longDisplayString] withFile: nil];
}

#pragma mark -
#pragma mark private methods

- (void)menuWillOpen:(NSMenu *)menu
{
	if (!adium)
		adium = [SBApplication applicationWithBundleIdentifier:@"com.adiumX.adiumX"];

	if ([adium isRunning] && [[adium activeChat] exists])
	{	
		[adiumMenuItem setEnabled: YES];
	}
	else
	{
		[adiumMenuItem setEnabled: NO];
	}
	
	
}

- (NSString *) trimmedDisplayString: (NSString *) displayString
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSInteger maxLength = [defaults integerForKey: @"maxDisplayLength"];
	if (maxLength < 8)
		maxLength = 8;
	
	//NSString *displayString = [self longDisplayString];
	
	if ([displayString length] >= maxLength)
	{
		displayString = [displayString substringToIndex: maxLength - 3];
		displayString = [displayString stringByAppendingString: @"..."];
	}
	
	return displayString;
}

// creates a menu item in the status menu
- (void) createStatusItem
{
	NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
	
	if (statusItem)
	{	
		[statusBar removeStatusItem: statusItem];
		[statusItem release];
		statusItem = nil;
	}

	NSString *title = [self displayString];

	
	NSMenu *menu = [[[NSMenu alloc] initWithTitle:@"menu title"] autorelease];
	[menu setDelegate: self];
	[menu setAutoenablesItems: NO];
//	NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:@"Preferences" action:@selector(openPreferences:) keyEquivalent:[NSString string]] autorelease];
//	[menu addItem: menuItem];
	
	[menu addItemWithTitle:@"Copy To Clip Board" action:@selector(copyCurrentTrackInfoToClipBoard:) keyEquivalent: [NSString string]];
	
	
	
	[menu addItemWithTitle:@"Send To Active Adium Chat" action:@selector(sendCurrentTrackToAdium:) keyEquivalent: [NSString string]];
	adiumMenuItem = [menu itemWithTitle: @"Send To Active Adium Chat"];
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	
	[menu addItemWithTitle:@"Check For Updates" action:@selector(checkForUpdates:) keyEquivalent: [NSString string]];

				
	[menu addItemWithTitle:@"Registration" action:@selector(openRegistrationWindow:) keyEquivalent:[NSString string]];

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
- (NSString *) longDisplayString
{
	NSString *playStatus = @"⌽ ";
	NSString *trackName = nil; //@"...";
	NSString *artistName = nil;// @"";
	NSString *delimiter = nil;// @"";
	NSString *kind = nil;
	NSString *streamTitle = nil;
	iTunesEPlS playerState;

	BOOL trackExists = NO;
	BOOL isStream = NO;

	
	if (!iTunes)
		iTunes = [[SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"] retain];

	if (![iTunes isRunning])
		return [NSString stringWithFormat:@"%@",playStatus];
	
	iTunesTrack *currentTrack = [iTunes currentTrack];

	
	if ([currentTrack exists] && [iTunes isRunning])
	{
		trackName = [[currentTrack name] copy];	
		artistName = [[currentTrack artist] copy];
 		kind = [[currentTrack kind] copy];
		streamTitle = [[iTunes currentStreamTitle] copy];
		playerState = [iTunes playerState];
		trackExists = YES;
	}
	else
	{
		return [NSString stringWithFormat:@"%@",playStatus];
	}


	if ([kind containsString: @"stream" ignoringCase: YES])
		isStream = YES;

	if (trackExists)
	{
		delimiter = @" - ";
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
		
	
		/*
		 why are we doing it here and not earlier as we know if it it a stream or not?
		 because many stream providers fuck up their title tags and put their station's name
		 into the stream-title. the currently played song title is then stored as a comment (or is not sent at all).
		 so we try to get the real track title here
		 */
		if (isStream)
		{
			if (streamTitle && ![streamTitle isEqualToString: @""])
			{				
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
			else
			{
				NSLog(@"no stream title!");
			}
		}
	}

	
	//	iTunesEPlSStopped = 'kPSS',
//	iTunesEPlSPlaying = 'kPSP',
//	iTunesEPlSPaused = 'kPSp',
//	iTunesEPlSFastForwarding = 'kPSF',
//	iTunesEPlSRewinding = 'kPSR'

	if (playerState == iTunesEPlSPlaying)
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

- (NSString *) displayString
{
	NSString *dispString = [self longDisplayString];
//	NSLog(@"long: %@", dispString);
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults boolForKey: @"trimDisplayStringLength"])
	{
		NSInteger maxLength = [defaults integerForKey: @"maxDisplayLength"];
		if ([dispString length] >= maxLength)
		{
			dispString = [self trimmedDisplayString: dispString];
		}
	}
	//NSLog(@"ret: %@", dispString);
	return dispString;
}

//will reconnect to iTunes
//this might be neccessary when our bridge dies
- (void) handleReconnectTimer: (NSTimer *) timer
{
	[iTunes release];
	iTunes = nil;
	iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];

/*	[NSTimer scheduledTimerWithTimeInterval: 10.0
									 target: self
								   selector: @selector(handleReconnectTimer:)
								   userInfo: nil
									repeats: NO];*/
	
}

// the timer's main loop. fetches command from server and processes it
- (void) handlePollTimer: (NSTimer *) timer
{
	//work against lag.
	//if isPolling == TRUE don't poll for new message
	
	NSString *displayString = [self displayString];
	
	if (![[statusItem title] isEqualToString: displayString])
		[self createStatusItem];
	
	
	
	/*[NSTimer scheduledTimerWithTimeInterval: 0.3
									 target: self
								   selector: @selector(handlePollTimer:)
								   userInfo: nil
									repeats: NO];*/
}

#pragma mark -
#pragma mark Application Delegate Methods

- (BOOL) isRegistrationValid
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSString *registeredTo = [defaults stringForKey: @"registeredTo"];
	NSString *serial = [defaults stringForKey: @"serial"];

	if (!registeredTo || !serial)
		return NO;

	if ([[self serialForName: registeredTo] isEqualToString: serial])
		return YES;
	
	return NO;
}


//lol rot 13
- (NSString *) serialForName: (NSString *) name
{
	name = [name uppercaseString];
	name = [name stringByReplacingOccurrencesOfString:@" " withString:@""];
	//XXXX-XXXX-XXXX-XXXX-XXXX
	if ([name length] < 20)
		name = [name stringByPaddingToLength: 20 withString:@"K" startingAtIndex: 0];

	
	NSMutableString *serial1 = [NSMutableString string];
	for (int i = 0; i < 5; i++)
	{
		NSRange r;
		r.location = i * 4;
		r.length = 4;
		[serial1 appendString: [name substringWithRange: r]];
		if (i < 4)
			[serial1 appendString: @"-"];
	}
	
	NSString *serial2 = [NSString rot13: serial1];
	
	return serial2;
}

- (void) registerForName: (NSString *) name andSerial: (NSString *) serial
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

//	serial = [self serialForName: name];
	
	[defaults setObject: name forKey: @"registeredTo"];
	[defaults setObject: serial forKey: @"serial"];
	
	[defaults synchronize];
}

- (void) checkRegistration
{
	isRegistered = [self isRegistrationValid];
}

// called by cocoa when our app is loaded and ready to run
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  [NSNumber numberWithBool: YES], @"trimDisplayStringLength",
						  [NSNumber numberWithInt: 64], @"maxDisplayLength",
						  nil];
	
	[defaults registerDefaults: dict];
	
	
	[self checkRegistration];
	//[self registerForName:@"Jaroslaw Szpilewski" andSerial: @"lolfail"];
	//isRegistered = [self isRegistrationValid];
	//NSLog(@"is this app registered? %i",isRegistered);
	
	//create the status menu item
	[self createStatusItem];//WithTitle: @"♫ ..."];

	//
	/*[NSTimer scheduledTimerWithTimeInterval: 10.0
									 target: self
								   selector: @selector(handleReconnectTimer:)
								   userInfo: nil
									repeats: NO];*/
	
	
	//starts the poll timer that will fetch new commands every 1.0 secs
	[self startPolling: self];
}


@end
