#import "GeneralPreferencePaneController.h"

@implementation GeneralPreferencePaneController

@synthesize startAtLoginTooltip;
@synthesize enableSmallCcreenModeTooltip;
@synthesize positionLeftTooltip;
@synthesize enableAdiumSupportTooltip;
@synthesize enableGrowlTooltip;


// init
- (id)init
{
    if (self = [super init])
    {
		[self setStartAtLoginTooltip: @"Sets whether Tune Buddy will start automatically on each system start."];
		[self setEnableSmallCcreenModeTooltip: @"If your system bar is too cluttered or you have a small screen like 13\" then you should enable this. Tune Buddy will then only display a small icon in the menu bar."];
		[self setPositionLeftTooltip: @"This will always position Tune Buddy to the most left of your menu bar icons."];
		[self setEnableAdiumSupportTooltip: @"Enables support for the Adium IM."];
		[self setEnableGrowlTooltip: @"If you have Growl installed track changes will be announced through a Growl notification."];
    }
    return self;
}

//=========================================================== 
// dealloc
//=========================================================== 
- (void) dealloc
{
    [startAtLoginTooltip release], startAtLoginTooltip = nil;
    [enableSmallCcreenModeTooltip release], enableSmallCcreenModeTooltip = nil;
    [positionLeftTooltip release], positionLeftTooltip = nil;
    [enableAdiumSupportTooltip release], enableAdiumSupportTooltip = nil;
	[enableGrowlTooltip release], enableGrowlTooltip = nil;
	
    [super dealloc];
}

+ (NSArray *)preferencePanes
{
    return [NSArray arrayWithObjects:[[[GeneralPreferencePaneController alloc] init] autorelease], nil];
}


- (NSView *)paneView
{
    BOOL loaded = YES;
    
    if (!prefsView) {
        loaded = [NSBundle loadNibNamed:@"GeneralPreferencePaneView" owner:self];
    }
    
    if (loaded) {
        return prefsView;
    }
    
    return nil;
}


- (NSString *)paneName
{
    return @"General";
}


- (NSImage *)paneIcon
{
    return [[[NSImage alloc] initWithContentsOfFile:
        [[NSBundle bundleForClass:[self class]] pathForImageResource:@"General_Prefs"]
        ] autorelease];
}


- (NSString *)paneToolTip
{
    return @"General Preferences";
}


- (BOOL)allowsHorizontalResizing
{
    return NO;
}


- (BOOL)allowsVerticalResizing
{
    return NO;
}

- (IBAction) colorWellDidFinish: (id) sender
{
	
}


@end
