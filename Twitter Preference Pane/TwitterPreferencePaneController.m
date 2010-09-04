#import "Tune Buddy_Prefix.pch"
#import "TwitterPreferencePaneController.h"
#import "EMKeychainItem.h"
#import "defs.h"
#import "NSString+URLEncoding.h"

@implementation TwitterPreferencePaneController
#pragma mark -
#pragma mark properties

@synthesize enableTwitterTooltip;
@synthesize nowplayingTooltip;
@synthesize musicMondayTooltip;
@synthesize tagSongTooltip;

#pragma mark -
#pragma mark initializers / destructors

// init
- (id)init
{
    if (self = [super init])
    {

        [self setEnableTwitterTooltip: @"If you enable Twitter support you will be able to post your current playing track to Twitter."];
        [self setNowplayingTooltip:  @"Will append a #nowplaying hashtag to the Twitter post."];
        [self setMusicMondayTooltip: @"On mondays a #musicmonday hashtag will be appended to the Twitter post."];
		[self setTagSongTooltip: @"The artist and song name will be tagged with a #."];
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
	[tagSongTooltip release], tagSongTooltip = nil;
	
    [super dealloc];
}

+ (NSArray *)preferencePanes
{
    return [NSArray arrayWithObjects:[[[TwitterPreferencePaneController alloc] init] autorelease], nil];
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
        loaded = [NSBundle loadNibNamed:@"TwitterPreferencePaneView" owner:self];
    }
    
    if (loaded) 
	{
        return prefsView;
    }
    
    return nil;
}


- (NSString *)paneName
{
    return @"Twitter";
}


- (NSImage *)paneIcon
{
    return [[[NSImage alloc] initWithContentsOfFile:
        [[NSBundle bundleForClass:[self class]] pathForImageResource:@"Twitter_Prefs.png"]
        ] autorelease];
}


- (NSString *)paneToolTip
{
    return @"Twitter Preferences";
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

	NSString *blah = [defs objectForKey: @"OAUTH_fx_twitter_KEY"];
	if (blah)
	{
		[authButton setTitle: @"Re-Authenticate Tune Buddy"];
	}
	else
	{
		[authButton setTitle: @"Authenticate Tune Buddy"];
	}
	
}
- (IBAction) twitterSucks: (id) sender
{
	[[NSApp delegate] authTwitterAndPostTweetAfterwards: NO];
}


@end
