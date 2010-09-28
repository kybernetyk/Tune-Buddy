#import "Tune Buddy_Prefix.pch"
#import "FacebookPreferencePaneController.h"
#import "EMKeychainItem.h"
#import "defs.h"
#import "NSString+URLEncoding.h"

@implementation FacebookPreferencePaneController
#pragma mark -
#pragma mark properties

@synthesize enableFacebookTooltip;
@synthesize extendedPostTooltip;

#pragma mark -
#pragma mark initializers / destructors

// init
- (id)init
{
    if (self = [super init])
    {

        [self setEnableFacebookTooltip: @"If you enable Facebook support you will be able to post your current playing track to your Facebook wall."];
        [self setExtendedPostTooltip:  @"Enable this option to make your Facebook updates look awesome."];
    }
    return self;
}



//=========================================================== 
// dealloc
//=========================================================== 
- (void) dealloc
{
	[self setEnableFacebookTooltip: nil];
	[self setExtendedPostTooltip: nil];
    [super dealloc];
}

+ (NSArray *)preferencePanes
{
    return [NSArray arrayWithObjects:[[[FacebookPreferencePaneController alloc] init] autorelease], nil];
}



/*
 we need this callback as simply closing the preferences window will not send the text fields action.
 so we save here our credentials if the user closes the prefs pane.
 */
- (void) preferencesWindowWillClose: (id) sender
{
}

- (NSView *)paneView
{
    BOOL loaded = YES;
    
    if (!prefsView) 
	{
        loaded = [NSBundle loadNibNamed:@"FacebookPreferencePaneView" owner:self];
    }
    
    if (loaded) 
	{
        return prefsView;
    }
    
    return nil;
}


- (NSString *)paneName
{
    return @"Facebook";
}


- (NSImage *)paneIcon
{
    return [[[NSImage alloc] initWithContentsOfFile:
        [[NSBundle bundleForClass:[self class]] pathForImageResource:@"Facebook_Prefs.png"]
        ] autorelease];
}


- (NSString *)paneToolTip
{
    return @"Facebooks Preferences";
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

	NSString *blah = [defs objectForKey: @"facebookAccessToken"];
	if (blah)
	{
		[authButton setTitle: @"Re-Authenticate Tune Buddy"];
	}
	else
	{
		[authButton setTitle: @"Authenticate Tune Buddy"];
	}
	
}
- (IBAction) facebookSucks: (id) sender
{
	[[NSApp delegate] deauthFacebook];

	

	
	[[NSApp delegate] authFacebookAndPostAfterwars: NO];
}


@end
