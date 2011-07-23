#import <Cocoa/Cocoa.h>
#import "SS_PreferencePaneProtocol.h"

@interface ClientPreferencePaneController : NSObject <SS_PreferencePaneProtocol> 
{
	NSString *clientTooltip;
	    IBOutlet NSView *prefsView;
}

@property (readwrite, retain) NSString *clientTooltip;

@end
