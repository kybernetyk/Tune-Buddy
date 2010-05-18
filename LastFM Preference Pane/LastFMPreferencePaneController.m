#import "LastFMPreferencePaneController.h"
#import "AGKeychain.h"
#import "LastFMAuth.h"

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
//	NSLog(@"OMG TWITTER THE WINDOW WILL CLOSE!");
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
	
	BOOL keychainItemExists = [AGKeychain checkForExistanceOfKeychainItem: @"Tune Buddy LastFM Credentials" 
															 withItemKind: @"application password" 
															  forUsername: twitterUsername];
	if (keychainItemExists)
	{
		NSString *pass = [AGKeychain getPasswordFromKeychainItem:@"Tune Buddy LastFM Credentials" 
													withItemKind: @"application password" 
													 forUsername: twitterUsername];
		
//		NSLog(@"twitter pass: %@", pass);
		[password setStringValue: pass];
	}
	
	
	//NSLog(@"exitst? %i", existsTwitterKeychain);
	
	//[AGKeychain 
	
	//+ (BOOL)addKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind forUsername:(NSString *)username withPassword:(NSString *)password;
	
	
//
	
	//NSLog(@"twitter did show!");
//	[self updateWindowWithRegistrationInfo];
	
	
	
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
	
	BOOL keychainItemExists = [AGKeychain checkForExistanceOfKeychainItem: @"Tune Buddy LastFM Credentials" 
															 withItemKind: @"application password" 
															  forUsername: twitterUsername];
	
	if (!keychainItemExists)
	{
		NSLog(@"adding new keychain item with credentials: %@ / %@", twitterUsername, [password stringValue]);
		[AGKeychain addKeychainItem: @"Tune Buddy LastFM Credentials" 
					   withItemKind: @"application password" 
						forUsername: twitterUsername 
					   withPassword: [password stringValue] ];
	}
	else
	{
		NSLog(@"modifying existing keychain item with credentials: %@ / %@", twitterUsername, [password stringValue]);
		[AGKeychain modifyKeychainItem: @"Tune Buddy LastFM Credentials" 
						  withItemKind: @"application password" 
						   forUsername: twitterUsername 
					   withNewPassword: [password stringValue]];
	}
	
	
}

- (IBAction) usernameChanged: (id) sender
{
//	NSLog(@"username changed!");
	
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	NSString *twitterUsername = [defs objectForKey: @"lastFMUsername"];
	
	BOOL keychainItemExists = [AGKeychain checkForExistanceOfKeychainItem: @"Tune Buddy LastFM Credentials" 
															 withItemKind: @"application password" 
															  forUsername: twitterUsername];
	if (keychainItemExists)
	{
		NSString *pass = [AGKeychain getPasswordFromKeychainItem:@"Tune Buddy LastFM Credentials" 
													withItemKind: @"application password" 
													 forUsername: twitterUsername];
		//NSLog(@"keychain item for this user exists already. pass is: %@",pass);		
		[password setStringValue: pass];
	}
	else
	{
//		NSLog(@"username not found ... creating new keychains item");
		[self saveToKeychain];	
	}

}

- (IBAction) passwordChanged: (id) sender
{
	[self saveToKeychain];
	
//	NSLog(@"password changed!");
}


@end
