#import "UpdatingPreferencePaneController.h"
//#import "AppDelegate.h"

@implementation UpdatingPreferencePaneController
#pragma mark -
#pragma mark properties

@synthesize checkForUpdatesTooltip;
@synthesize submitAnonymizedHardwareStatisticsTooltip;
#pragma mark -
#pragma mark initializers / destructors

// init
- (id)init
{
	self = [super init];
    if (self) {
        [self setCheckForUpdatesTooltip: @"Every day an automatic check for new versions of Tune Buddy will be performed."];
        [self setSubmitAnonymizedHardwareStatisticsTooltip: @"You can choose to submit anonymized hardware statistics about your Mac. (CPU/Size of RAM/etc). This will help us make better software. Only hardware stats are submitted - no personal information will be ever collected by this app and/or submitted to us!"];
    }
    return self;
}



//=========================================================== 
// dealloc
//=========================================================== 
- (void) dealloc
{
    [checkForUpdatesTooltip release], checkForUpdatesTooltip = nil;
    [submitAnonymizedHardwareStatisticsTooltip release], submitAnonymizedHardwareStatisticsTooltip = nil;
	
    [super dealloc];
}



- (IBAction) checkForUpdatesNow: (id) sender
{
	[[NSApp delegate] checkForUpdates: sender];
}

+ (NSArray *)preferencePanes
{
    return [NSArray arrayWithObjects:[[[UpdatingPreferencePaneController alloc] init] autorelease], nil];
}


- (NSView *)paneView
{
    BOOL loaded = YES;
    
    if (!prefsView) {
        loaded = [NSBundle loadNibNamed:@"UpdatingPreferencePaneView" owner:self];
    }
    
    if (loaded) {
        return prefsView;
    }
    
    return nil;
}


- (NSString *)paneName
{
    return @"Updating";
}


- (NSImage *)paneIcon
{
    return [[[NSImage alloc] initWithContentsOfFile:
        [[NSBundle bundleForClass:[self class]] pathForImageResource:@"Updating_Prefs"]
        ] autorelease];
}


- (NSString *)paneToolTip
{
    return @"Updating Preferences";
}


- (BOOL)allowsHorizontalResizing
{
    return NO;
}


- (BOOL)allowsVerticalResizing
{
    return NO;
}


@end
