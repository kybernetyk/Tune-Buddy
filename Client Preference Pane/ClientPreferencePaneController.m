#import "ClientPreferencePaneController.h"

@implementation ClientPreferencePaneController

@synthesize clientTooltip;

// init
- (id)init
{
    if (self = [super init])
    {
		[self setClientTooltip: @"Here you can select which music player Tune Buddy will attach to."];
    }
    return self;
}

//=========================================================== 
// dealloc
//=========================================================== 
- (void) dealloc
{
	[self setClientTooltip: nil];	
    [super dealloc];
}

+ (NSArray *)preferencePanes
{
    return [NSArray arrayWithObjects:[[[ClientPreferencePaneController alloc] init] autorelease], nil];
}


- (NSView *)paneView
{
    BOOL loaded = YES;
    
    if (!prefsView) {
        loaded = [NSBundle loadNibNamed:@"ClientPreferencePaneView" owner:self];
    }
    
    if (loaded) {
        return prefsView;
    }
    
    return nil;
}


- (NSString *)paneName
{
    return @"Client";
}


- (NSImage *)paneIcon
{
    return [[[NSImage alloc] initWithContentsOfFile:
        [[NSBundle bundleForClass:[self class]] pathForImageResource:@"Client_Prefs"]
        ] autorelease];
}


- (NSString *)paneToolTip
{
    return @"Client Preferences";
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
