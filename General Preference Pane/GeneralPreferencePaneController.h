#import <Cocoa/Cocoa.h>
#import "SS_PreferencePaneProtocol.h"

@interface GeneralPreferencePaneController : NSObject <SS_PreferencePaneProtocol> 
{
    IBOutlet NSView *prefsView;
	IBOutlet NSColorWell *colorWell;

	NSString *startAtLoginTooltip;
	NSString *enableSmallCcreenModeTooltip;
    NSString *positionLeftTooltip;
	NSString *enableAdiumSupportTooltip;
	NSString *enableGrowlTooltip;
}

@property (readwrite, retain) NSString *startAtLoginTooltip;
@property (readwrite, retain) NSString *enableSmallCcreenModeTooltip;
@property (readwrite, retain) NSString *positionLeftTooltip;
@property (readwrite, retain) NSString *enableAdiumSupportTooltip;
@property (readwrite, retain) NSString *enableGrowlTooltip;



@end
