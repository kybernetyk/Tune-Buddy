#import "Tune Buddy_Prefix.pch"
#import "LastFMPreferencePaneController.h"
#import "EMKeychainItem.h"
#import "LastFMAuth.h"
#include "defs.h"

@implementation LastFMPreferencePaneController
#pragma mark -
#pragma mark properties

@synthesize enableTwitterTooltip;
@synthesize nowplayingTooltip;
@synthesize musicMondayTooltip;
@synthesize twitterUsernameTooltip;
@synthesize twitterPasswordTooltip;
#pragma mark -
#pragma mark initializers / destructors

// init
- (id)init
{
    if (self = [super init])
    {

        [self setEnableTwitterTooltip: @"If you enable LastFM support Tune Buddy will scrobble your playlist to LastFM."];
        [self setNowplayingTooltip:  @"Will append a #nowplaying hashtag to the Twitter post."];
        [self setMusicMondayTooltip: @"On mondays a #musicmonday hashtag will be appended to the Twitter post."];
        [self setTwitterUsernameTooltip: @"Your LastFM username."];
        [self setTwitterPasswordTooltip: @"Your LastFM password."];
    }
    return self;
}



//=========================================================== 
// dealloc
//=========================================================== 
- (void) dealloc
{
    [enableTwitterTooltip release], enableTwitterTooltip = nil;
    [nowplayingTooltip release], nowplayingTooltip = nil;
    [musicMondayTooltip release], musicMondayTooltip = nil;
    [twitterUsernameTooltip release], twitterUsernameTooltip = nil;
    [twitterPasswordTooltip release], twitterPasswordTooltip = nil;
	
    [super dealloc];
}

+ (NSArray *)preferencePanes
{
    return [NSArray arrayWithObjects:[[[LastFMPreferencePaneController alloc] init] autorelease], nil];
}



/*
 we need this callback as simply closing the preferences window will not send the text fields action.
 so we save here our credentials if the user closes the prefs pane.
 */
- (void) preferencesWindowWillClose: (id) sender
{
		NSLog(@"OMG LASTHM THE WINDOW WILL CLOSE!");
	[self saveToKeychain];
}

- (NSView *)paneView
{
    BOOL loaded = YES;
    
    if (!prefsView) 
	{
        loaded = [NSBundle loadNibNamed:@"LastFMPreferencePaneView" owner:self];
    }
    
    if (loaded) 
	{
        return prefsView;
    }
    
    return nil;
}


- (NSString *)paneName
{
    return @"LastFM";
}


- (NSImage *)paneIcon
{
    return [[[NSImage alloc] initWithContentsOfFile:
        [[NSBundle bundleForClass:[self class]] pathForImageResource:@"LastFM_Prefs.png"]
        ] autorelease];
}


- (NSString *)paneToolTip
{
    return @"LastFM Preferences";
}


- (BOOL)allowsHorizontalResizing
{
    return NO;
}


- (BOOL)allowsVerticalResizing
{
    return NO;
}

- (void) didShow: (id) sender
{
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	NSString *twitterUsername = [defs objectForKey: @"lastFMUsername"];
	
	EMGenericKeychainItem *keychainItem = [EMGenericKeychainItem genericKeychainItemForService: KEYCHAIN_LASTFM withUsername: twitterUsername];
	if (keychainItem)
	{
		
		NSString *pass = [keychainItem password];
		[password setStringValue: pass];
	}
	
	
	
}

- (void) saveToKeychain
{
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	NSString *twitterUsername = [defs objectForKey: @"lastFMUsername"];

	if (!twitterUsername || [twitterUsername isEqualToString: @""] || [twitterUsername length] <= 0)
	{	
		NSLog(@"invalid lastFM username");
		return;
	}
	
	NSString *pass = [password stringValue];
	if (!pass || [pass isEqualToString: @""] || [pass length] <= 0)
	{	
		NSLog(@"invalid lastFM password");
		return;
	}
	
	EMGenericKeychainItem *keychainItem = [EMGenericKeychainItem genericKeychainItemForService: KEYCHAIN_LASTFM withUsername: twitterUsername];
	if (keychainItem)
	{
		[keychainItem setPassword: [password stringValue]];
	}
	else 
	{
		[EMGenericKeychainItem addGenericKeychainItemForService: KEYCHAIN_LASTFM withUsername: twitterUsername password: [password stringValue]];
	}
	
}

- (IBAction) usernameChanged: (id) sender
{
//	NSLog(@"username changed!");
	
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	NSString *twitterUsername = [defs objectForKey: @"lastFMUsername"];
	
	EMGenericKeychainItem *keychainItem = [EMGenericKeychainItem genericKeychainItemForService: KEYCHAIN_LASTFM withUsername: twitterUsername];
	if (keychainItem)
	{
		//[keychainItem setPassword: [password stringValue]];
		[password setStringValue: [keychainItem password]];
	}
	else 
	{
		[self saveToKeychain];
	}
	
}

- (IBAction) passwordChanged: (id) sender
{
	[self saveToKeychain];
	

}


@end
