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
#import "MGTwitterEngine.h"



@implementation AppDelegate
@synthesize isRegistered;

#pragma mark -
#pragma mark public IB accessable methods

- (IBAction) sendCurrentTrackToTwitter: (id) sender
{
	NSLog(@"sending track to twitter!");
	
	if (lastConnectionIdentifier)
	{
		NSLog(@"won't send as we're sending already!");
		
		return;
	}
		
	
	[twitterEngine release];
	twitterEngine = nil;
	
	// Create a TwitterEngine and set our login details.
    twitterEngine = [[MGTwitterEngine alloc] initWithDelegate:self];
	[twitterEngine setClearsCookies: YES];
	[twitterEngine setUsesSecureConnection: YES];
	[twitterEngine setClientName:@"µTweet" version:@"0.1" URL:@"http://www.fluxforge.com" token:@"mutweet"];
    
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *user = [defaults stringForKey: @"twitterUsername"];
	NSString *pass = [defaults stringForKey: @"twitterPassword"];
	
	[twitterEngine setUsername: user password: pass];
	
	lastConnectionIdentifier = [twitterEngine sendUpdate: [self longDisplayString]];
	
}

- (IBAction) openPreferencesWindow: (id) sender
{
	[NSApp activateIgnoringOtherApps: YES];
	
	if (preferencesWindowController)
	{
		[preferencesWindowController showPreferencesWindow];
		return;
	}
	
	// Determine path to the sample preference panes
	NSString *pathToPanes = [[NSString stringWithFormat:@"%@/Contents/Resources/", [[NSBundle mainBundle] bundlePath]]
							 stringByStandardizingPath];
	
	preferencesWindowController = [[SS_PrefsController alloc] initWithPanesSearchPath:pathToPanes bundleExtension:@"bundle"];
	
	// Set which panes are included, and their order.
	[preferencesWindowController setPanesOrder:[NSArray arrayWithObjects:@"General",@"Twitter",@"Updating",@"Registration", nil]];
	// Show the preferences window.
	[preferencesWindowController showPreferencesWindow];
	

	
}

// starts the poll Timer that will fetch new commands every 1.0 secs
- (IBAction) startPolling: (id) sender
{
	[NSTimer scheduledTimerWithTimeInterval: 1.0
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
	

	//transformer for hidden = !xxxEnabled
	NSValueTransformer *tran = [NSValueTransformer valueTransformerForName: NSNegateBooleanTransformerName];
	NSDictionary *opts = [NSDictionary dictionaryWithObject: tran forKey: @"NSValueTransformer"];
	
	
	adiumMenuItem = [menu addItemWithTitle:@"Send To Active Adium Chat" action:@selector(sendCurrentTrackToAdium:) keyEquivalent: [NSString string]];
	[twitterMenuItem bind: @"hidden" toObject: [NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.adiumEnabled" options:opts];
	

	twitterMenuItem = [menu addItemWithTitle:@"Send To Twitter" action:@selector(sendCurrentTrackToTwitter:) keyEquivalent: [NSString string]];
	[twitterMenuItem bind: @"hidden" toObject: [NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.twitterEnabled" options:opts];

	
	[menu addItem:[NSMenuItem separatorItem]];
	
	[menu addItemWithTitle:@"Preferences" action:@selector(openPreferencesWindow:) keyEquivalent: [NSString string]];
	
	//[menu addItemWithTitle:@"Check For Updates" action:@selector(checkForUpdates:) keyEquivalent: [NSString string]];

				
//	[menu addItemWithTitle:@"Registration" action:@selector(openRegistrationWindow:) keyEquivalent:[NSString string]];

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
		trackName = [[[currentTrack name] copy] autorelease];	
		artistName = [[[currentTrack artist] copy] autorelease];
 		kind = [[[currentTrack kind] copy] autorelease];
		streamTitle = [[[iTunes currentStreamTitle] copy] autorelease];
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
						  [NSNumber numberWithBool: NO], @"twitterEnabled",
						  [NSNumber numberWithBool: YES], @"adiumEnabled",
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



#pragma mark ---
#pragma mark MGTwitterEngineDelegate methods
- (void)requestSucceeded:(NSString *)connectionIdentifier
{
	  NSLog(@"Request succeeded for connectionIdentifier = %@", connectionIdentifier);
	lastConnectionIdentifier = nil;
}


- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error
{
    NSLog(@"Request failed for connectionIdentifier = %@, error = %@ (%@)", 
	 connectionIdentifier, 
	 [error localizedDescription], 
	 [error userInfo]);
	
	lastConnectionIdentifier = nil;
}


- (void)statusesReceived:(NSArray *)statuses forRequest:(NSString *)connectionIdentifier
{
}


- (void)directMessagesReceived:(NSArray *)messages forRequest:(NSString *)connectionIdentifier
{
	  NSLog(@"Got direct messages for %@:\r%@", connectionIdentifier, messages);
}


- (void)userInfoReceived:(NSArray *)userInfo forRequest:(NSString *)connectionIdentifier
{
	    NSLog(@"Got user info for %@:\r%@", connectionIdentifier, userInfo);
}


- (void)miscInfoReceived:(NSArray *)miscInfo forRequest:(NSString *)connectionIdentifier
{
		NSLog(@"Got misc info for %@:\r%@", connectionIdentifier, miscInfo);
}

- (void)searchResultsReceived:(NSArray *)searchResults forRequest:(NSString *)connectionIdentifier
{
		NSLog(@"Got search results for %@:\r%@", connectionIdentifier, searchResults);
}


- (void)imageReceived:(NSImage *)image forRequest:(NSString *)connectionIdentifier
{
	  NSLog(@"Got an image for %@: %@", connectionIdentifier, image);
    
    // Save image to the Desktop.
    //NSString *path = [[NSString stringWithFormat:@"~/Desktop/%@.tiff", connectionIdentifier] stringByExpandingTildeInPath];
    //[[image TIFFRepresentation] writeToFile:path atomically:NO];
}

- (void)connectionFinished
{
	if ([twitterEngine numberOfConnections] == 0)
	{
		NSLog(@"connection finished. %i open connections left ...",[twitterEngine numberOfConnections]);
		//[NSApp terminate:self];
	}
}


@end
