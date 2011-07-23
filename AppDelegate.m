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
#import "SpotifyBridgeOperation.h"
#ifndef MAS_VERSION
	#import "PFMoveApplication.h"
#endif
#import "NSString+Additions.h"
#import "EMKeychainItem.h"
#import <Growl/Growl.h>
#import "LastFMNotificationOperation.h"
#import "LastFMSubmissionOperation.h"
#import "LastFMAuth.h"
#import "OAuthConsumer.h"
#import "TwitterAuthWindowController.h"
#import "FacebookAuthWindowController.h"
#import "FacebookShareOperation.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "WelcomeWindowController.h"
#import "PFMoveApplication.h"

@interface AppDelegate()
- (void) checkRegistration;
- (void) openBuyPage: (id) sender;
- (void) contactSupport: (id) sender;
- (void) openRegistrationPane: (id) sender;
- (void) reorderIcon: (id) sender;
- (void) authTwitterAndPostTweetAfterwards: (BOOL) postAfterwards;
@end

@implementation AppDelegate
#pragma mark -
#pragma mark properties

@synthesize playStatus;
@synthesize isRegistered;
@synthesize longDisplayString;
@synthesize isExpired;
@synthesize albumArt;
@synthesize	trackArtist;
@synthesize trackName;
@synthesize albumName;
@synthesize trackRating;
@synthesize trackPlayCount;

#pragma mark -
#pragma mark autostart

- (void)enableLoginItemWithLoginItemsReference:(LSSharedFileListRef )theLoginItemsRefs ForPath:(CFURLRef)thePath 
{
	NSLog(@"enable login item!");
	
	// We call LSSharedFileListInsertItemURL to insert the item at the bottom of Login Items list.
	LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(theLoginItemsRefs, kLSSharedFileListItemLast, NULL, NULL, thePath, NULL, NULL);		
	if (item)
		CFRelease(item);
}

- (void)disableLoginItemWithLoginItemsReference:(LSSharedFileListRef )theLoginItemsRefs ForPath:(CFURLRef)thePath 
{
	NSLog(@"disable login item!");
	
	UInt32 seedValue;
	
	// We're going to grab the contents of the shared file list (LSSharedFileListItemRef objects)
	// and pop it in an array so we can iterate through it to find our item.
	NSArray  *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(theLoginItemsRefs, &seedValue);
	
	for (id item in loginItemsArray) 
	{		
		LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
		if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &thePath, NULL) == noErr) 
		{
			if ([[(NSURL *)thePath path] hasPrefix: [[NSBundle mainBundle] bundlePath]])
				LSSharedFileListItemRemove(theLoginItemsRefs, itemRef); // Deleting the item
		}
	}
	
	[loginItemsArray release];
}

- (IBAction)addLoginItem:(id)sender 
{
//	CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:SGApplicationPath];
	
	// Create a reference to the shared file list.
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if (loginItems) 
	{
		NSURL *bundleURL = [NSURL fileURLWithPath: [[NSBundle mainBundle] bundlePath]];
		
		NSLog(@"my bundle path: %@", bundleURL);
		
		BOOL addToLogin = [[NSUserDefaults standardUserDefaults] boolForKey: @"startAtLogin"];
		
		if (addToLogin)
			[self enableLoginItemWithLoginItemsReference: loginItems ForPath: (CFURLRef)bundleURL];
		else
			[self disableLoginItemWithLoginItemsReference: loginItems ForPath: (CFURLRef)bundleURL];
		
		/*if ([[oOpenAtLogin selectedCell] state] == YES)
			[self enableLoginItemWithLoginItemsReference:loginItems ForPath:url];
		else
			[self disableLoginItemWithLoginItemsReference:loginItems ForPath:url];*/
	}

	CFRelease(loginItems);
}


- (void) createBridgeOperation {
//	[bridgeOperation autorelease];
	[backgroundOperationQueue cancelAllOperations];

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *selectedClient = [defaults valueForKey: @"selectedClient"];
	NSLog(@"Selected Client: %@", selectedClient);
	if ([selectedClient isEqualToString: @"Automatic"]) {
		bridgeOperation = [[[SpotifyBridgeOperation alloc] init] autorelease];
		[bridgeOperation setDelegate: self];	
		[backgroundOperationQueue addOperation: bridgeOperation];
		
		bridgeOperation = [[[iTunesBridgeOperation alloc] init] autorelease];		
		[bridgeOperation setDelegate: self];	
		[backgroundOperationQueue addOperation: bridgeOperation];
	} else {
		if ([selectedClient isEqualToString: @"Spotify"]) {
			bridgeOperation = [[[SpotifyBridgeOperation alloc] init] autorelease];		
		}
		
		//fall back is always iTunes
		if ([selectedClient isEqualToString: @"iTunes"] ||
			[selectedClient length] == 0 ||
			!bridgeOperation) {
			bridgeOperation = [[[iTunesBridgeOperation alloc] init] autorelease];
		}
		
		[bridgeOperation setDelegate: self];
		[backgroundOperationQueue addOperation: bridgeOperation];
	}
}

#pragma mark -
#pragma mark Application Delegate Methods

// called by cocoa when our app is loaded and ready to run
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
/*	CFStringRef ref = SecCopyErrorMessageString (-25299, NULL);
	
	NSLog(@"%@",ref);
*/	
	
//	[EMGenericKeychainItem addGenericKeychainItemForService: @"lalalala" withUsername: @"peniskopf" password: @"fisckendich"];
	
	//[EMGenericKeychainItem addGenericKeychainItemForService:@"SomeAppService" withUsername:@"Joe" password:@"supersecure!"];
	
#ifndef MAS_VERSION
	PFMoveToApplicationsFolderIfNecessary();
#endif
	
	NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey: @"LastFMAPIKey"];
	if (!data)
	{
		NSDate *date = [NSDate date];

		NSTimeInterval interval = [date timeIntervalSinceReferenceDate];
		
		NSData *data = [NSData dataWithBytes: &interval length: sizeof(interval)];
		
		[[NSUserDefaults standardUserDefaults] setObject: data forKey: @"LastFMAPIKey"];
	}
	else
	{
		NSTimeInterval *intervaal = ((NSTimeInterval*)[data bytes]);
		NSTimeInterval firstRun = *intervaal;

		NSDate *date = [NSDate date];
		NSTimeInterval now = [date timeIntervalSinceReferenceDate];
		
		
		NSTimeInterval secondsrun = now - firstRun;
		
		//NSLog(@"we're running %f seconds - %f days left ...",secondsrun, (2592000.0 - secondsrun)/86400.0);
		
		//if (secondsrun >= 2592000.0)
		///if (secondsrun >= 1.0)
		if (secondsrun >= 2592000.0)
		{
			NSLog(@"expired!");
			[self setIsExpired: YES];

		}
		
/*		NSDate *date = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate: myint];
		
		
		NSLog(@"first run time: %@",date);
		NSLog(@"now: %@",[NSDate date]);
		NSLog(@"trial time: %i", [[NSDate date] timeIntervalSinceReferenceDate] - myint );*/
	}
	
	
//	EMInternetKeychainItem *keychainItem = [[EMKeychainProxy sharedProxy] internetKeychainItemForServer:@"apple.com" withUsername:@"sjobs" path:@"/httpdocs" port:21 protocol:kSecProtocolTypeFTP];

/*	[[EMKeychainProxy sharedProxy] setLogsErrors: YES];

	EMInternetKeychainItem *keyChainItem = [[EMKeychainProxy sharedProxy] internetKeychainItemForServer: @"http://twitter.com"
																						   withUsername: @"fettemama"
																								   path: nil
																								   port: 80 
																							   protocol: kSecProtocolTypeHTTP];
	
	NSLog(@"keychian: %@", keyChainItem);*/
	
	
	//NSScreen *screen = [[NSScreen screens] objectAtIndex: 0];
	
	BOOL shallEnableSmallScreenMode = NO;
	
//	NSLog(@"screen width: %f", [screen frame].size.width);
	
#ifdef SMALL_SCREENMODE_INSTEAD_OF_SCROLLING
	if ([screen frame].size.width < 1300.0)
		shallEnableSmallScreenMode = YES;
#endif
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	//	[defaults setObject:[NSArchiver archivedDataWithRootObject:myColor
	//														forKey:@"myColor"]];

	NSData *fontData = [NSArchiver archivedDataWithRootObject: [NSColor blackColor]];
	
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  [NSNumber numberWithBool: YES], @"trimDisplayStringLength",
						  [NSNumber numberWithBool: NO], @"twitterEnabled",
						  [NSNumber numberWithBool: NO], @"lastFMEnabled",
						  [NSNumber numberWithBool: YES], @"enableMusicMonday",
						  [NSNumber numberWithBool: YES], @"adiumEnabled",
						  [NSNumber numberWithBool: YES], @"startAtLogin",
						  [NSNumber numberWithBool: YES], @"appendNowPlayingToTwitterPosts",
						  [NSNumber numberWithBool: YES], @"keepAlwaysLeft",
						  [NSNumber numberWithBool: NO], @"tagSongOnTwitter",
						  [NSNumber numberWithBool: YES], @"facebookEnabled",
						  [NSNumber numberWithBool: YES], @"detailedFacebookPost",
						  [NSNumber numberWithBool: shallEnableSmallScreenMode], @"smallScreenModeEnabled",
						  [NSNumber numberWithBool: shallEnableSmallScreenMode], @"growlEnabled", //enable growl notifications when small screen mode is enabled. don't bother big screen users with growl
						  fontData, @"statusItemForegroundColor",
						  [NSNumber numberWithBool: YES], @"showWelcome",
						  [NSNumber numberWithBool: YES], @"scrollingEnabled",
						  @"Automatic", @"selectedClient",
						  nil];
	
	[defaults registerDefaults: dict];
	smallScreenModeEnabled = [[NSUserDefaults standardUserDefaults] boolForKey: @"smallScreenModeEnabled"];
	
	NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
	if (IsInApplicationsFolder(bundlePath)) 
	{
		NSLog(@"app is in app folder. adding myself to autostart ...");
		[self addLoginItem: self];	
	}
	
	
	
	[self checkRegistration];
	
	if ([self isExpired] && ![self isRegistered])
	{
		NSAlert *al = [NSAlert alertWithMessageText: @"Tune Buddy: Trial Time Expired" 
									  defaultButton: @"Ok" 
									alternateButton: @"Buy" 
										otherButton: @"Enter License Key" 
						  informativeTextWithFormat:@"Your Tune Buddy trial is expired. Tune Buddy will stop displaying song information. If you want to continue using Tune Buddy please click the 'Buy' button to purchase a license."];
		[al setAlertStyle: NSCriticalAlertStyle];
		
		NSInteger retcode = [al runModal];
		
		if (retcode == NSAlertAlternateReturn)
		{
			[self openBuyPage: self];
		}
		
		if (retcode == NSAlertOtherReturn)
		{
			[self openRegistrationPane: self];
		}
		
	}
	
	[GrowlApplicationBridge setGrowlDelegate: self];
	
	//[self registerForName:@"Jaroslaw Szpilewski" andSerial: @"lolfail"];
	//isRegistered = [self isRegistrationValid];
	//NSLog(@"is this app registered? %i",isRegistered);

	//auth with last fm to get shit going
	
	BOOL lfm = [defaults boolForKey: @"lastFMEnabled"];
	if (lfm)
		[[LastFMAuth sharedLastFMAuth] password];
	
		
	backgroundOperationQueue = [[NSOperationQueue alloc] init];
	[backgroundOperationQueue setMaxConcurrentOperationCount: 5];
	
	[self createBridgeOperation];
	NSLog(@"bridge op: %@", bridgeOperation);
	
	NSUserDefaultsController *defc = [NSUserDefaultsController sharedUserDefaultsController];
	[defc addObserver: self forKeyPath: @"values.smallScreenModeEnabled" options: NSKeyValueObservingOptionNew context: @"smallScreenModeEnabled"];
	[defc addObserver: self forKeyPath: @"values.startAtLogin" options: NSKeyValueObservingOptionNew context: @"startAtLogin"];
	[defc addObserver: self forKeyPath: @"values.keepAlwaysLeft" options: NSKeyValueObservingOptionNew context: @"keepAlwaysLeft"];
	[defc addObserver: self forKeyPath: @"values.statusItemForegroundColor" options: NSKeyValueObservingOptionNew context: @"statusItemForegroundColor"];
	[defc addObserver: self forKeyPath: @"values.lastFMUsername" options: NSKeyValueObservingOptionNew context: @"lastFMUsername"];
	[defc addObserver: self forKeyPath: @"values.scrollingEnabled" options: NSKeyValueObservingOptionNew context: @"scrollingEnabled"];
	[defc addObserver: self forKeyPath: @"values.selectedClient" options: NSKeyValueObservingOptionNew context: @"selectedClient"];
	
	
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"showWelcome"]) {
	//	[self authFacebookAndPostAfterwars: NO];
		[NSApp activateIgnoringOtherApps: YES];

		WelcomeWindowController *wwc = [[WelcomeWindowController alloc] initWithWindowNibName: @"WelcomeWindow"];
		[[wwc window] makeKeyWindow];
	}
}


#pragma mark -
#pragma mark KVO observing (for user defaults)
/* we observe the user defaults controller to act when the user changes maxBandwidthUsage or maxConcurrentDownloadOperations */
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	NSString *contextString = (NSString *)context;
	NSLog(@"context string: %@", contextString);
	
	if ([contextString isEqualToString: @"smallScreenModeEnabled"])
	{
		smallScreenModeEnabled = [[NSUserDefaults standardUserDefaults] boolForKey: @"smallScreenModeEnabled"];
		
		[self createStatusItem];
		return;
	}

	if ([contextString isEqualToString: @"startAtLogin"])
	{
		[self addLoginItem: self];
		return;
	}
	
	if ([contextString isEqualToString: @"lastFMUsername"])
	{
		NSLog(@"last fm username changed biatch!");
		[[LastFMAuth sharedLastFMAuth] reset];
		return;
	}
	
	if ([contextString isEqualToString: @"scrollingEnabled"]) {
		[self createStatusItem];
		return;
	}
	
	if ([contextString isEqualToString: @"selectedClient"]) {
		[self createBridgeOperation];		
		[self createStatusItem];
		return;
	}



	if ([contextString isEqualToString: @"keepAlwaysLeft"])
	{
		//smallScreenModeEnabled = [[NSUserDefaults standardUserDefaults] boolForKey: @"smallScreenModeEnabled"];
		[self reorderIcon: self];
		
//		[self createStatusItem];
		return;
	}
	
	
/*	if ([contextString isEqualToString: @"twitterUsername"])
	{
		NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
		NSLog(@"new username for twitter: %@", [defs objectForKey: @"twitterUsername"] );
								[defs setObject: @"yadayada" forKey: @"twitterUsername"];
								
								
		return;
	}

	if ([contextString isEqualToString: @"twitterPassword"])
	{
		NSLog(@"new pass for twitter: %@", [[NSUserDefaults standardUserDefaults] objectForKey: @"twitterPassword"] );
		
		return;
	}*/
	
	if ([contextString isEqualToString: @"statusItemForegroundColor"])
	{
		[self createStatusItem];
		return;
	}
	
	
	
	[super observeValueForKeyPath:keyPath
						 ofObject:object
						   change:change
						  context:context];
}



- (void)menuWillOpen:(NSMenu *)menu
{
	if (smallScreenModeEnabled)
	{
		//[smallScreenModeMenuItem setTitle: [self displayString]];
	}
	
	if (!adium)
		adium = [[SBApplication applicationWithBundleIdentifier:@"com.adiumX.adiumX"] retain];
	
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
/*- (void) createStatusItem
{
	BOOL smallScreenModeEnabled = [[NSUserDefaults standardUserDefaults] boolForKey: @"smallScreenModeEnabled"];
	
	NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
	
	if (statusItem)
	{	
		[statusBar removeStatusItem: statusItem];
		[statusItem release];
		statusItem = nil;
	}
	
	NSString *title = @"♫";
	
	if (!smallScreenModeEnabled)
		title = [self displayString];
	
	
	NSMenu *menu = [[[NSMenu alloc] initWithTitle:@"menu title"] autorelease];
	statusBarMenu = menu;
	[menu setDelegate: self];
	[menu setAutoenablesItems: NO];
	//	NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:@"Preferences" action:@selector(openPreferences:) keyEquivalent:[NSString string]] autorelease];
	//	[menu addItem: menuItem];

	
	if (smallScreenModeEnabled)
	{
		smallScreenModeMenuItem = [menu addItemWithTitle: [self displayString] action: @selector(copyCurrentTrackInfoToClipBoard:) keyEquivalent: [NSString string]];	
		[menu addItem:[NSMenuItem separatorItem]];
	}
	
	[menu addItemWithTitle:@"Copy To Clip Board" action: @selector(copyCurrentTrackInfoToClipBoard:) keyEquivalent: [NSString string]];
	
	
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
	
}*/


// creates a menu item in the status menu
- (void) createStatusItem
{
	//BOOL smallScreenModeEnabled = [[NSUserDefaults standardUserDefaults] boolForKey: @"smallScreenModeEnabled"];
	
	NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
	
	
	NSString *title = [[self playStatus] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
	
	if (!smallScreenModeEnabled)
		title = [self displayString];
	
	
	if (!statusBarMenu)
	{	
		statusBarMenu = [[NSMenu alloc] initWithTitle:@"menu title"];
		[statusBarMenu setDelegate: self];
		[statusBarMenu setAutoenablesItems: NO];
	}
	
	
	/*if (smallScreenModeEnabled)
	{*/
		if (!smallScreenModeMenuItem)
		{	
			smallScreenModeMenuItem = [[NSMenuItem alloc] initWithTitle: [self longDisplayString] action: @selector (copyCurrentTrackInfoToClipBoard:) keyEquivalent:[NSString string]];
			
			[statusBarMenu insertItem: smallScreenModeMenuItem atIndex: 0];

			smallScreenMenuSeperator = [[NSMenuItem separatorItem] retain];

			
			if ([self isExpired] && ![self isRegistered])
			{
				[statusBarMenu addItemWithTitle:@"Buy Tune Buddy" action:@selector(openBuyPage:) keyEquivalent: [NSString string]];
				[statusBarMenu addItemWithTitle:@"Enter License Key" action:@selector(openRegistrationPane:) keyEquivalent: [NSString string]];
				[statusBarMenu insertItem: smallScreenMenuSeperator atIndex: 3];
			}
			else
			{
				[statusBarMenu insertItem: smallScreenMenuSeperator atIndex: 1];
			}
		}
		else 
		{
			[smallScreenModeMenuItem setTitle: [self longDisplayString]];
			[smallScreenModeMenuItem setHidden: NO];
			[smallScreenMenuSeperator setHidden: NO];
		}
/*	}
	else
	{
		[smallScreenModeMenuItem setHidden: YES];
		[smallScreenMenuSeperator setHidden: YES];
	}*/

#ifdef LITE_VERSION
	if (!fullVersionMenuItem)
	{
		fullVersionMenuItem = [statusBarMenu addItemWithTitle: @"Get Tune Buddy Full Version" action:@selector(openBuyPage:) keyEquivalent: [NSString string]];
		//		[statusBarMenu addItem:[NSMenuItem separatorItem]];
		
	}
#endif

	if (!copyToClipboardMenuItem)
		copyToClipboardMenuItem = [statusBarMenu addItemWithTitle:@"Copy To Clip Board" action: @selector(copyCurrentTrackInfoToClipBoard:) keyEquivalent: [NSString string]];
	
	
	//transformer for hidden = !xxxEnabled
	NSValueTransformer *tran = [NSValueTransformer valueTransformerForName: NSNegateBooleanTransformerName];
	NSDictionary *opts = [NSDictionary dictionaryWithObject: tran forKey: @"NSValueTransformer"];

#ifndef LITE_VERSION
	if (!adiumMenuItem)
	{
		adiumMenuItem = [statusBarMenu addItemWithTitle:@"Send To Active Adium Chat" action:@selector(sendCurrentTrackToAdium:) keyEquivalent: [NSString string]];
		[adiumMenuItem bind: @"hidden" toObject: [NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.adiumEnabled" options:opts];
	}
	
	if (!twitterMenuItem)
	{
		twitterMenuItem = [statusBarMenu addItemWithTitle:@"Send To Twitter" action:@selector(sendCurrentTrackToTwitter:) keyEquivalent: [NSString string]];
		[twitterMenuItem bind: @"hidden" toObject: [NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.twitterEnabled" options:opts];
	}
	
	if (!facebookMenuItem)
	{
		facebookMenuItem = [statusBarMenu addItemWithTitle: @"Send To Facebook" action:@selector(sendCurrentTrackToFacebook:) keyEquivalent: [NSString string]];
		[facebookMenuItem bind: @"hidden" toObject: [NSUserDefaultsController sharedUserDefaultsController] withKeyPath: @"values.facebookEnabled" options:opts];
		[statusBarMenu addItem:[NSMenuItem separatorItem]];
		
	}	
#endif
	if (!contactSupportMenuItem)
	{
#ifdef LITE_VERSION
		[statusBarMenu addItem:[NSMenuItem separatorItem]];
#endif
		contactSupportMenuItem = [statusBarMenu addItemWithTitle:@"Contact Support" action:@selector(contactSupport:) keyEquivalent: [NSString string]];
		

	}
	
	if (!preferencesMenuItem)
	{	
		preferencesMenuItem = [statusBarMenu addItemWithTitle:@"Preferences" action:@selector(openPreferencesWindow:) keyEquivalent: [NSString string]];
		
		[statusBarMenu addItem:[NSMenuItem separatorItem]];		
	}
	
	if (!quitMenuItem)
	{	
		quitMenuItem = [statusBarMenu addItemWithTitle:@"Quit" action:@selector(quitAppByMenu:) keyEquivalent:[NSString string]];
	}
	
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
//	NSData *fontData = [defs objectForKey: @"statusItemForegroundColor"];
//	NSColor *fontColor = [NSUnarchiver unarchiveObjectWithData: fontData];
	
	
	
	
//	NSFont *font = [NSFont fontWithName:@"Verdana" size: 11.0f];
	//NSLog(@"%@",font);
//	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys: font,@"NSFont",fontColor,NSForegroundColorAttributeName,  nil];
	//NSAttributedString *attributedTitle = [[[NSAttributedString alloc] initWithString: title attributes: attributes] autorelease];
	
//	[defaults setObject:[NSArchiver archivedDataWithRootObject:myColor
//														forKey:@"myColor"]];


	
	if (!statusItem)
	{	

		if ([defs boolForKey: @"keepAlwaysLeft"] && [statusBar respondsToSelector:@selector(_statusItemWithLength:withPriority:)])
		{
			statusItem = [statusBar _statusItemWithLength:0 withPriority:INT_MIN ];
			[statusItem setLength:0];
		}
		else
		{
			statusItem = [statusBar statusItemWithLength: NSVariableStatusItemLength];	
		}
			
		[statusItem setEnabled: YES];
		[statusItem setHighlightMode: YES];
		[statusItem setMenu: statusBarMenu];


		if ([defs boolForKey: @"keepAlwaysLeft"] && [statusBar respondsToSelector:@selector(_statusItemWithLength:withPriority:)])
		{
			[ statusItem setLength:NSVariableStatusItemLength ];
		}
		

		[statusItem retain];
	}
	
//	[statusItem setAttributedTitle: attributedTitle];
	#define SYSTEM_STATUS_BAR_HEIGHT ([[NSStatusBar systemStatusBar] thickness])
	statusView = [[FXScrollingView alloc] initWithFrame:NSMakeRect(0, 0, SYSTEM_STATUS_BAR_HEIGHT, SYSTEM_STATUS_BAR_HEIGHT)];


	statusView.maximumWidth = [[[NSScreen screens] objectAtIndex: 0] frame].size.width/6.4;
	//self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	statusItem.view = statusView;
			statusItem.menu.delegate = statusView;
//	[statusItem menu = mainMenu;
//	statusItem.menu.delegate = trackInfoView;
	
	//trackInfoView.menu = mainMenu;
	statusView.statusItem = statusItem;
	//trackInfoView.artworkView.image = [NSImage imageNamed: @"icon.icns"];
	[statusView.titleField setStringValue: title];
//	[trackInfoView.titleField setAttributedStringValue: attributedTitle];
}


//recreate our item to move it to the most left
- (void) reorderIcon: (id) sender
{
	NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
	
	if (statusItem)
	{	
		[statusBar removeStatusItem: statusItem];
		[statusItem release];
		statusItem = nil;
	}
	
	[self createStatusItem];
	
}

#pragma mark -
#pragma mark MGTwitterEngineDelegate methods
- (void)requestSucceeded:(NSString *)connectionIdentifier
{
	  NSLog(@"Request succeeded for connectionIdentifier = %@", connectionIdentifier);
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
	
	if ([[error localizedDescription] containsString: @"401"])
	{
		NSLog (@"wrong username!");
		
		
/*		NSAlert *al = [NSAlert alertWithMessageText:@"Tune Buddy: Twitter Error" defaultButton:@"Ok" alternateButton: nil otherButton: nil informativeTextWithFormat:@"Twitter returned the error code 401. This usually means that your username and password don't match."];
		[al setAlertStyle: NSCriticalAlertStyle];
		
		[al runModal];*/
		lastConnectionIdentifier = nil;
		
		[twitterEngine autorelease];
		twitterEngine = nil;
		
		[self authTwitterAndPostTweetAfterwards: YES];
		
		return;
//		[[NSAlert alertWithError: error] runModal];

	}
	else
	{
		NSAlert *al = [NSAlert alertWithMessageText:@"Tune Buddy: Twitter Error" defaultButton:@"Ok" alternateButton: nil otherButton: nil informativeTextWithFormat:@"Twitter returned an error: %@", [error localizedDescription]];
		[al setAlertStyle: NSCriticalAlertStyle];
		
		[al runModal];
		
	}
	
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
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	
	// Create a TwitterEngine and set our login details.
    twitterEngine = [[MGTwitterEngine alloc] initWithDelegate:self];
	[twitterEngine setClearsCookies: YES];
	[twitterEngine setUsesSecureConnection: YES];
	[twitterEngine setClientName:@"µTweet" version:@"0.1" URL:@"http://www.fluxforge.com" token:@"mutweet"];
    
//	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//	NSString *user = [defaults stringForKey: @"twitterUsername"];
//	NSString *pass = [defaults stringForKey: @"twitterPassword"];
	
	
	OAToken *token = [[OAToken alloc] initWithUserDefaultsUsingServiceProviderName: @"twitter" prefix:@"fx"];
	if (!token)
	{
		NSLog(@"no twitter token found ... let's authorize!");
		[self authTwitterAndPostTweetAfterwards: YES];
		return;
	}
	
	OAConsumer *consumer = [[OAConsumer alloc] initWithKey: TWITTER_API_KEY secret: TWITTER_API_SECRET];
	
	
	NSLog(@"init twitter with token: %@",token);
	[twitterEngine setUseOAuth: YES];
	[twitterEngine setConsumer: consumer];
	[twitterEngine setAccessToken: token];
	
	[token autorelease];
	[consumer autorelease];
	
	

	
	NSCalendar *gregorian = [[NSCalendar alloc]	initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *weekdayComponents = [gregorian components:NSWeekdayCalendarUnit fromDate: [NSDate date]];
	NSInteger weekday = [weekdayComponents weekday];
	[gregorian release];
	
	NSString *appendString = @"";
	
	if ([defaults boolForKey: @"appendNowPlayingToTwitterPosts"])
		appendString = [appendString stringByAppendingString:@" #nowplaying"];
	
	if ([defaults boolForKey: @"enableMusicMonday"] && weekday == 2) //mondays!
		appendString = [appendString stringByAppendingString: @" #musicmonday"];

	NSString *tstr = nil;
	NSString *dispString = [NSString stringWithString: [self longDisplayString]];
	
	if ([defaults boolForKey: @"tagSongOnTwitter"]) //mondays!
	{	
		dispString = [dispString stringByReplacingOccurrencesOfString: @" " withString: @" #"];
		dispString = [dispString stringByReplacingOccurrencesOfString: @"#-" withString: @"-"];
		dispString = [dispString stringByReplacingOccurrencesOfString: @"#(" withString: @"(#"];
		dispString = [dispString stringByReplacingOccurrencesOfString: @"#{" withString: @"{#"];
		dispString = [dispString stringByReplacingOccurrencesOfString: @"#." withString: @"."];
		dispString = [dispString stringByReplacingOccurrencesOfString: @"#," withString: @","];
	}
	
	if ([appendString length] > 0)
		tstr = [NSString stringWithFormat: @"%@%@",dispString,appendString];
	else
		tstr = [NSString stringWithFormat: @"%@",dispString];
	

	lastConnectionIdentifier = [twitterEngine sendUpdate: tstr];	
	NSLog(@"sending string %@ with id %@",tstr, lastConnectionIdentifier);
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
#ifdef MAS_VERSION
#ifndef LITE_VERSION
	[preferencesWindowController setPanesOrder:[NSArray arrayWithObjects:@"General", @"Client",@"Twitter",@"LastFM",@"Facebook", nil]];
#else
	[preferencesWindowController setPanesOrder:[NSArray arrayWithObjects:@"General",nil]];
#endif
	
#else
	[preferencesWindowController setPanesOrder:[NSArray arrayWithObjects:@"General", @"Client",@"Twitter",@"LastFM",@"Facebook",@"Updating",@"Registration", nil]];
#endif
	// Show the preferences window.
	[preferencesWindowController showPreferencesWindow];
	
	[NSApp activateIgnoringOtherApps: YES];	
	
}


- (IBAction) checkForUpdates: (id) sender
{
#ifndef MAS_VERSION
	[sparkle checkForUpdates: sender];
#endif
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
		[adium = [SBApplication applicationWithBundleIdentifier:@"com.adiumX.adiumX"] retain];
	
	if (![adium isRunning])
		return;
	
	AdiumChat *currentChat = [adium activeChat];
	[currentChat sendMessage: [self longDisplayString] withFile: nil];
}

- (IBAction) sendCurrentTrackToFacebook: (id) sender
{
	FacebookShareOperation *fso = [[[FacebookShareOperation alloc] init] autorelease];
	[fso setMessage: [self longDisplayString]];
	[fso setDelegate: self];
	[fso setAlbumArt: [self albumArt]];
	[fso setAlbumName: [self albumName]];
	[fso setTrackName: [self trackName]];
	[fso setTrackArtist: [self trackArtist]];
	[fso setTrackRating: [self trackRating]];
	[fso setTrackPlayCount: [self trackPlayCount]];
	[backgroundOperationQueue addOperation: fso];
}

- (void) facebookShareOperationDidSucceed: (FacebookShareOperation *) operation
{
	facebookAuthFailCount = 0;
	NSLog(@"fb share was cool!");
}

- (void) facebookShareOperationDidFail: (FacebookShareOperation *) operation
{
	facebookAuthFailCount ++;
	NSLog(@"auth fail count: %i", facebookAuthFailCount);

	NSLog(@"fb share was not cool!");
	[self deauthFacebook];

	if (facebookAuthFailCount < 3)
	{
		[self authFacebookAndPostAfterwars: YES];	
	}
	else
	{
		facebookAuthFailCount = 0;
		//[self authFacebookAndPostAfterwars: NO];	
		NSAlert *al = [NSAlert alertWithMessageText: @"Facebook critical auth error" 
									  defaultButton: @"Ok" 
									alternateButton: nil
										otherButton: nil
						  informativeTextWithFormat:@"There seems to be a critical authentication error with Facebook. Please sign into your Facebook profile and remove the permissions you granted to Tune Buddy. Then try to re-authenticate again."];
		[al setAlertStyle: NSCriticalAlertStyle];
		[al runModal];
	}
}


- (NSInteger) maxDisplayStringLength
{
	return ([[[NSScreen screens] objectAtIndex: 0] frame].size.width/6.4)/6.0;
}
	 
#pragma mark -
#pragma mark display string mangling
- (NSString *) trimmedDisplayString: (NSString *) displayString
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"scrollingEnabled"])
		return displayString;
	
	NSInteger maxLength = [self maxDisplayStringLength];
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
	if ([defaults boolForKey: @"trimDisplayStringLength"])	{
		NSInteger maxLength = [self maxDisplayStringLength];
		if ([dispString length] >= maxLength) {
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

- (void) openBuyPage: (id) sender
{
#ifdef MAS_VERSION
#ifdef LITE_VERSION
	[NSApp activateIgnoringOtherApps: YES];
	
	WelcomeWindowController *wwc = [[WelcomeWindowController alloc] initWithWindowNibName: @"WelcomeWindow"];
	[[wwc window] makeKeyWindow];
#endif
	
#else
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://www.fluxforge.com/tune-buddy/buy/"]];
#endif
}

- (void) contactSupport: (id) sender
{
#ifdef MAS_VERSION
	#ifdef LITE_VERSION
	NSURL *url = [NSURL URLWithString: @"mailto:support@fluxforge.com?subject=Tune%20Buddy%20Lite%20Support"];
	#else
	NSURL *url = [NSURL URLWithString: @"mailto:support@fluxforge.com?subject=Tune%20Buddy%20MAS%20Support"];
	#endif
#else
	NSURL *url;
	if ([self isRegistered])
		url = [NSURL URLWithString: @"mailto:support@fluxforge.com?subject=Tune%20Buddy%20Support"];
	else
		url = [NSURL URLWithString: @"mailto:support@fluxforge.com?subject=Tune%20Buddy%20Trial%20Support"];	
#endif
	[[NSWorkspace sharedWorkspace] openURL: url];
}


- (void) openRegistrationPane: (id) sender
{
	[self openPreferencesWindow: self];
	[preferencesWindowController loadPrefsPaneNamed: @"Registration" display: YES];
}

#pragma mark -
#pragma mark Growl Delegate
- (NSDictionary *) registrationDictionaryForGrowl
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSArray arrayWithObjects: @"TuneBuddyTrackDidChange",nil],
			GROWL_NOTIFICATIONS_ALL,
			[NSArray arrayWithObjects: @"TuneBuddyTrackDidChange",nil],
			GROWL_NOTIFICATIONS_DEFAULT,
			nil];
}

- (NSString *) applicationNameForGrowl
{
	return @"Tune Buddy";
}


#pragma mark -
#pragma mark Growl Notifier
- (void) notifyGrowlOfTrackChange
{
/*	+[GrowlApplicationBridge
	  notifyWithTitle:(NSString *)title
	  description:(NSString *)description
	  notificationName:(NSString *)notificationName
	  iconData:(NSData *)iconData
	  priority:(signed int)priority
	  isSticky:(BOOL)isSticky
	  clickContext:(id)clickContext]*/
	NSLog(@"notfieng growl ...");
	
	BOOL shouldNotify = [[NSUserDefaults standardUserDefaults] boolForKey: @"growlEnabled"];
	if (!shouldNotify)
		return;
	
	if ([[self playStatus] containsString: @"⌽"])
		return;
	
	[GrowlApplicationBridge notifyWithTitle: @"Now playing"
								description: [self longDisplayString]
						   notificationName: @"TuneBuddyTrackDidChange" 
								   iconData: nil
								   priority: 0 
								   isSticky: NO 
							   clickContext: nil];
	
}

#pragma mark -
#pragma mark scrobble delegate
/*- (void) lastFMScrobbler: (LastFMScrobbler *) aScrobbler submissionDidSucceed: (BOOL) yesno
{
	if (yesno == YES)
	{
		[scrobbleQueue release];
		scrobbleQueue = nil;
	}

	[aScrobbler autorelease];
}*/


- (void) lastFmScrobblerSubmissionDidSucceed: (LastFMSubmissionOperation *) aScrobbler
{
	NSLog(@"lastFmScrobblerSubmissionDidSucceed:");
	[scrobbleQueue release];
	scrobbleQueue = nil;
//	[aScrobbler autorelease];
}

- (void) lastFmScrobblerSubmissionDidFail: (LastFMSubmissionOperation *) aScrobbler
{
	NSLog(@"lastFmScrobblerSubmissionDidFail:");	
}

- (void) lastFmScrobblerNotificationDidSucceed: (LastFMNotificationOperation *) aScrobbler
{
	NSLog(@"lastFmScrobblerNotificationDidSucceed:");	
}

- (void) lastFmScrobblerNotificationDidFail: (LastFMNotificationOperation *) aScrobbler
{
	NSLog(@"lastFmScrobblerNotificationDidFail:");	
}


#pragma mark -
#pragma mark itunes bridge delegate
- (LastFMNotificationOperation *) notificationOperationWithDictionary: (NSDictionary *) infoDict
{
	LastFMNotificationOperation *scrobbler = [[LastFMNotificationOperation alloc] init];
	
	[scrobbler setDelegate: self];
	
	
	[scrobbler setArtistName: [infoDict objectForKey: @"artistName"]];
	[scrobbler setTrackName: [infoDict objectForKey: @"trackName"]];
	[scrobbler setAlbumName: [infoDict objectForKey: @"albumName"]];
	[scrobbler setTrackLength: [infoDict objectForKey: @"trackLength"]];
	[scrobbler setTrackPlaybackStartTime: [infoDict objectForKey: @"trackPlaybackStartTime"]];

	return [scrobbler autorelease];
}


- (void) iTunesTrackDidPass20PercentMark: (NSDictionary *) infoDict
{
	if (![[infoDict objectForKey: @"isPlaying"] boolValue])
	{	
		//[infoDict release]; //we must release this here
		return;
		
	}
	
	if (!scrobbleQueue)
	{
		scrobbleQueue = [[NSMutableArray alloc] initWithCapacity: 10];
	}
	
	//	NSLog(@"OK MAN! WE HAVE 20perc!!");
	
	BOOL isStream = [[infoDict objectForKey: @"isStream"] boolValue];
	
	//we don't want to scrobble online radio
	if (!isStream)
	{	
		
		NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
		BOOL doScrobble = [defs boolForKey: @"lastFMEnabled"];

		if (doScrobble)
		{
			[scrobbleQueue addObject: [NSDictionary dictionaryWithDictionary: infoDict]];
			NSLog(@"added %@ - %@ to submission queue (count) = %i",[infoDict objectForKey: @"artistName"],[infoDict objectForKey:@"trackName"], [scrobbleQueue count]);
			LastFMNotificationOperation *notificationScrobbler = [self notificationOperationWithDictionary: [NSDictionary dictionaryWithDictionary: infoDict]];
			if (notificationScrobbler)
				[backgroundOperationQueue addOperation: notificationScrobbler];
			
		}
	}
	
//	[infoDict release]; //we must release this here

}


- (void) iTunesTrackDidChangeTo: (NSDictionary *) infoDict
{
//	BOOL smallScreenModeEnabled = [[NSUserDefaults standardUserDefaults] boolForKey: @"smallScreenModeEnabled"];

	if ([self isExpired] && ![self isRegistered])
	{
		[self setLongDisplayString: @"$$$ - Please register Tune Buddy now!"];
		[self setPlayStatus: @"$$$"];
	}
	else
	{
		[self setLongDisplayString: [infoDict objectForKey: @"displayString"]];
		[self setPlayStatus: [infoDict objectForKey: @"displayStatus"]];

		[self setAlbumArt: [infoDict objectForKey: @"albumArt"]];
		[self setAlbumName: [infoDict objectForKey:@"albumName"]];
		[self setTrackName: [infoDict objectForKey: @"trackName"]];
		[self setTrackArtist: [infoDict objectForKey: @"artistName"]];
		[self setTrackRating: [infoDict objectForKey: @"trackRating"]];
		[self setTrackPlayCount: [infoDict objectForKey: @"trackPlayCount"]];
		NSLog(@"my album art is: %@", [self albumArt]);
	}
//	NSLog(@"%@",infoDict);
	
	
	//if (!smallScreenModeEnabled)
	{
		NSString *displayString = [self displayString];

		//if track name is longer than displayString a change won't be registered :-(
		//if (![[statusItem title] isEqualToString: displayString])
		
		//if (![[smallScreenModeMenuItem title] isEqualToString: [self longDisplayString]])
		[self createStatusItem];
		
		[self notifyGrowlOfTrackChange];

		//only scrobble when user plays
		if ([[infoDict objectForKey: @"isPlaying"] boolValue])
		{
			NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
			BOOL doScrobble = [defs boolForKey: @"lastFMEnabled"];

			if (doScrobble)
			{
				if (!scrobbleQueue)
					scrobbleQueue = [[NSMutableArray alloc] initWithCapacity: 10];
				
				NSArray *copyScrobbleQueue = [NSArray arrayWithArray: scrobbleQueue];
				LastFMSubmissionOperation *scrobbler = [[LastFMSubmissionOperation alloc] init];
				[scrobbler setDelegate: self];
				[scrobbler setDictsToSubmit: copyScrobbleQueue];
				
				[backgroundOperationQueue addOperation: scrobbler];
				[scrobbler release];
			}
	
			//our original queue will be erased when we get a successful scrobble
			
		}
	}
	
	//[infoDict release]; //we must release this here
}

- (void) bridgePing: (NSDictionary *) infoDict
{
	if ([[infoDict objectForKey: @"isPlaying"] boolValue]) {
		if ([[self longDisplayString] isEqualToString: [infoDict objectForKey: @"displayString"]]) {
			return;
		}
		[self setLongDisplayString: [infoDict objectForKey: @"displayString"]];
		[self setPlayStatus: [infoDict objectForKey: @"displayStatus"]];
		
		[self setAlbumArt: [infoDict objectForKey: @"albumArt"]];
		[self setAlbumName: [infoDict objectForKey:@"albumName"]];
		[self setTrackName: [infoDict objectForKey: @"trackName"]];
		[self setTrackArtist: [infoDict objectForKey: @"artistName"]];
		[self setTrackRating: [infoDict objectForKey: @"trackRating"]];
		[self setTrackPlayCount: [infoDict objectForKey: @"trackPlayCount"]];
		[self createStatusItem];
		
	} else {
		//[self setLongDisplayString: @"x"];
	}
}

#pragma mark -
#pragma mark twitter auth

- (void) authTwitterAndPostTweetAfterwards: (BOOL) postAfterwards
{
	[NSApp activateIgnoringOtherApps: YES];

	TwitterAuthWindowController *twc = [[TwitterAuthWindowController alloc] initWithWindowNibName: @"TwitterAuthWindow"];
	
	if (postAfterwards)
		[twc setDelegate: self];
	
	[[twc window] center];
	[twc showWindow: self];
}

- (void) twitterWindowControllerDidSucceed
{
	[self sendCurrentTrackToTwitter: self];
}

#pragma mark -
#pragma mark Facebook auth

- (void) authFacebookAndPostAfterwars: (BOOL) postAfterwards
{
	NSLog(@"auth and post afterwards ... %i", postAfterwards);
	[NSApp activateIgnoringOtherApps: YES];
	
	FacebookAuthWindowController *fwc = [[FacebookAuthWindowController alloc] initWithWindowNibName: @"FacebookAuthWindow"];
	
	if (postAfterwards)
		[fwc setDelegate: self];
	
	[[fwc window] center];
	[fwc showWindow: self];
	
}

- (void) deauthFacebook
{
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	NSString *token = [defs objectForKey: @"facebookAccessToken"];
	
	//	auth.expireSession
	ASIFormDataRequest *req = [[ASIFormDataRequest alloc] initWithURL: [NSURL URLWithString: @"https://api.facebook.com/method/auth.expireSession"]];
	[req setPostValue: token  forKey: @"access_token"];
	[req startSynchronous];
	[defs removeObjectForKey: @"facebookAccessToken"];
	[defs synchronize];
	
}

- (void) facebookWindowControllerDidSucceed
{
	NSLog(@"OMG WERE AUTHED WITH THE FACEBOOKS!");
	[self sendCurrentTrackToFacebook: self];
}

- (void) facebookWindowControllerDidFail
{
	NSLog(@"OMG WERE auth failed!");
	facebookAuthFailCount = 0;
}


@end
