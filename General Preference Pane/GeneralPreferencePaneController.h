#import <Cocoa/Cocoa.h>
#import "SS_PreferencePaneProtocol.h"

@interface GeneralPreferencePaneController : NSObject <SS_PreferencePaneProtocol> 
{
    IBOutlet NSView *prefsView;

	NSString *startAtLoginTooltip;
	NSString *enableSmallCcreenModeTooltip;
    NSString *positionLeftTooltip;
	NSString *enableAdiumSupport;
}

@property (readwrite, retain) NSString *startAtLoginTooltip;
@property (readwrite, retain) NSString *enableSmallCcreenModeTooltip;
@property (readwrite, retain) NSString *positionLeftTooltip;
@property (readwrite, retain) NSString *enableAdiumSupport;


@end
