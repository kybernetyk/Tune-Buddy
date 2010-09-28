#import <Cocoa/Cocoa.h>
#import "SS_PreferencePaneProtocol.h"

@interface FacebookPreferencePaneController : NSObject <SS_PreferencePaneProtocol> 
{
	IBOutlet NSView *prefsView;
	IBOutlet NSButton *authButton;

	NSString *enableFacebookTooltip;
	NSString *extendedPostTooltip;
}

#pragma mark -
#pragma mark properties

@property (readwrite, retain) NSString *enableFacebookTooltip;
@property (readwrite, retain) NSString *extendedPostTooltip;


- (IBAction) facebookSucks: (id) sender;

@end
