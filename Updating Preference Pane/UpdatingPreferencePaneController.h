#import <Cocoa/Cocoa.h>
#import "SS_PreferencePaneProtocol.h"

@interface UpdatingPreferencePaneController : NSObject <SS_PreferencePaneProtocol> 
{
    IBOutlet NSView *prefsView;

    NSString *checkForUpdatesTooltip;
	NSString *submitAnonymizedHardwareStatisticsTooltip;
	
}
#pragma mark -
#pragma mark properties

@property (readwrite, retain) NSString *checkForUpdatesTooltip;
@property (readwrite, retain) NSString *submitAnonymizedHardwareStatisticsTooltip;

- (IBAction) checkForUpdatesNow: (id) sender;

@end
