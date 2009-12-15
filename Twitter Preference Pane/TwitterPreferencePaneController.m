#import "TwitterPreferencePaneController.h"

@implementation TwitterPreferencePaneController


+ (NSArray *)preferencePanes
{
    return [NSArray arrayWithObjects:[[[TwitterPreferencePaneController alloc] init] autorelease], nil];
}


- (NSView *)paneView
{
    BOOL loaded = YES;
    
    if (!prefsView) {
        loaded = [NSBundle loadNibNamed:@"TwitterPreferencePaneView" owner:self];
    }
    
    if (loaded) {
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


@end
