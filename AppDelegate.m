//
//  AppDelegate.m
//  itunes control
//
//  Created by Jaroslaw Szpilewski on 07.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "Adium.h"
#import "NSString+Search.h"
#import "MGTwitterEngine.h"
#import "iTunesBridgeOperation.h"
#import "PFMoveApplication.h"
#import "NSString+Additions.h"

@implementation AppDelegate
@synthesize isRegistered;
@synthesize longDisplayString;



#pragma mark -
#pragma mark Application Delegate Methods
// called by cocoa when our app is loaded and ready to run
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	PFMoveToApplicationsFolderIfNecessary();
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  [NSNumber numberWithBool: YES], @"trimDisplayStringLength",
						  [NSNumber numberWithInt: 64], @"maxDisplayLength",
						  [NSNumber numberWithBool: NO], @"twitterEnabled",
						  [NSNumber numberWithBool: YES], @"enableMusicMonday",
						  [NSNumber numberWithBool: YES], @"adiumEnabled",
						  nil];
	
	[defaults registerDefaults: dict];
	
	
	[self checkRegistration];
	//[self registerForName:@"Jaroslaw Szpilewski" andSerial: @"lolfail"];
	//isRegistered = [self isRegistrationValid];
	//NSLog(@"is this app registered? %i",isRegistered);
	
	backgroundOperationQueue = [[NSOperationQueue alloc] init];
	[backgroundOperationQueue setMaxConcurrentOperationCount: 2];
	
	iTunesBridgeOperation *op = [[iTunesBridgeOperation alloc] init];
	[op setDelegate: self];
	
	[backgroundOperationQueue addOperation: op];
	
	
}

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


#pragma mark -
#pragma mark MGTwitterEngineDelegate methods
- (void)requestSucceeded:(NSString *)connectionIdentifier
{
//	  NSLog(@"Request succeeded for connectionIdentifier = %@", connectionIdentifier);
	lastConnectionIdentifier = nil;
	
	[twitterEngine autorelease];
	twitterEngine = nil;
}


- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error
{
    NSLog(@"Request failed for connectionIdentifier = %@, error = %@ (%@)", 
	 connectionIdentifier, 
	 [error localizedDescription], 
	 [error userInfo]);
	
	lastConnectionIdentifier = nil;
	
	[twitterEngine autorelease];
	twitterEngine = nil;
}


- (void)statusesReceived:(NSArray *)statuses forRequest:(NSString *)connectionIdentifier
{
}


- (void)directMessagesReceived:(NSArray *)messages forRequest:(NSString *)connectionIdentifier
{
//	  NSLog(@"Got direct messages for %@:\r%@", connectionIdentifier, messages);
}


- (void)userInfoReceived:(NSArray *)userInfo forRequest:(NSString *)connectionIdentifier
{
	  //  NSLog(@"Got user info for %@:\r%@", connectionIdentifier, userInfo);
}


- (void)miscInfoReceived:(NSArray *)miscInfo forRequest:(NSString *)connectionIdentifier
{
	//	NSLog(@"Got misc info for %@:\r%@", connectionIdentifier, miscInfo);
}

- (void)searchResultsReceived:(NSArray *)searchResults forRequest:(NSString *)connectionIdentifier
{
	//	NSLog(@"Got search results for %@:\r%@", connectionIdentifier, searchResults);
}


- (void)imageReceived:(NSImage *)image forRequest:(NSString *)connectionIdentifier
{
	// NSLog(@"Got an image for %@: %@", connectionIdentifier, image);
    
    // Save image to the Desktop.
    //NSString *path = [[NSString stringWithFormat:@"~/Desktop/%@.tiff", connectionIdentifier] stringByExpandingTildeInPath];
    //[[image TIFFRepresentation] writeToFile:path atomically:NO];
}

- (void)connectionFinished
{
	if ([twitterEngine numberOfConnections] == 0)
	{
		//NSLog(@"connection finished. %i open connections left ...",[twitterEngine numberOfConnections]);
		//[NSApp terminate:self];
	}
}

#pragma mark -
#pragma mark public IB accessable methods
- (IBAction) sendCurrentTrackToTwitter: (id) sender
{
	if (lastConnectionIdentifier)
	{
		NSLog(@"won't send as we're sending already!");
		
		return;
	}
	
	// Create a TwitterEngine and set our login details.
    twitterEngine = [[MGTwitterEngine alloc] initWithDelegate:self];
	[twitterEngine setClearsCookies: YES];
	[twitterEngine setUsesSecureConnection: YES];
	[twitterEngine setClientName:@"µTweet" version:@"0.1" URL:@"http://www.fluxforge.com" token:@"mutweet"];
    
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *user = [defaults stringForKey: @"twitterUsername"];
	NSString *pass = [defaults stringForKey: @"twitterPassword"];
	
	[twitterEngine setUsername: user password: pass];
	
	NSCalendar *gregorian = [[NSCalendar alloc]	initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *weekdayComponents = [gregorian components:NSWeekdayCalendarUnit fromDate: [NSDate date]];
	NSInteger weekday = [weekdayComponents weekday];
	[gregorian release];
	
	if ([defaults boolForKey: @"enableMusicMonday"] && weekday == 2) //mondays!
	{
		NSString *tstr = [NSString stringWithFormat: @"%@ #nowplaying #musicmonday",[self longDisplayString]];
		lastConnectionIdentifier = [twitterEngine sendUpdate: tstr];
	}
	else
	{
		NSString *tstr = [NSString stringWithFormat: @"%@ #nowplaying",[self longDisplayString]];
		lastConnectionIdentifier = [twitterEngine sendUpdate: tstr];
	}
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


- (IBAction) checkForUpdates: (id) sender
{
	[sparkle checkForUpdates: sender];
}


//quits the application if chosen from the status menu 
- (IBAction) quitAppByMenu : (id) sender
{
	[backgroundOperationQueue cancelAllOperations];
	
	[NSApp terminate: self];
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
#pragma mark display string mangling
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

- (NSString *) displayString
{
	NSString *dispString = [self longDisplayString];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults boolForKey: @"trimDisplayStringLength"])
	{
		NSInteger maxLength = [defaults integerForKey: @"maxDisplayLength"];
		if ([dispString length] >= maxLength)
		{
			dispString = [self trimmedDisplayString: dispString];
		}
	}
	return dispString;
}

#pragma mark -
#pragma mark registration 
- (BOOL) isRegistrationValid
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSString *registeredTo = [defaults stringForKey: @"registeredTo"];
	NSString *serial = [defaults stringForKey: @"serial"];
	
	if (!registeredTo || !serial)
		return NO;
	
	if ([[self serialForName: registeredTo] isEqualToString: serial])
	{	
		NSLog(@"we're registered!");
		
		return YES;
		
	}
	
	return NO;
}


//lol rot 13
/*- (NSString *) serialForName: (NSString *) name
{
	//name = [name uppercaseString];
	name = [name stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	//name = [name stringByReplacingOccurrencesOfString:@" " withString:@""];
	
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
	serial2 = [serial2 uppercaseString];
	
	NSLog(@"computed serial: %@", serial2);
	
	return serial2;
}*/

- (NSString *) serialForName: (NSString *) name
{
	NSInteger len = [name length];
	//NSLog(@"name: %@ - len: %i",name, len);
	//NSLog(@"md5: %@",[name md5]);

	if (len < 10)
		len = 15;
	if (len > 99)
		len = 50;

	NSInteger one = len - 3;
	NSInteger two = len;
	NSInteger three = len + 3;
	NSInteger four = len - 5;

	NSString *string = [NSString stringWithFormat: @"%i%i%i%i%i%i%i%i%i%i%i%i%i%i%i%i",
						one,two,three,four,two,four,one,three,three,four,one,two,one,three,four,one];
	
	string = [string uppercaseString];
	string = [string md5];

	name = [name md5];

	
	name = [name stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	//name = [name stringByReplacingOccurrencesOfString:@" " withString:@""];
	
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
	serial2 = [serial2 uppercaseString];
	
	//NSLog(@"computed serial: %@", serial2);
	
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


#pragma mark -
#pragma mark itunes bridge delegate
- (void) iTunesTrackDidChangeTo: (NSString *) newTrack
{
	[self setLongDisplayString: newTrack];

	NSString *displayString = [self displayString];
	
	if (![[statusItem title] isEqualToString: displayString])
		[self createStatusItem];
}

@end
