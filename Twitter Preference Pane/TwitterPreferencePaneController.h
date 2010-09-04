#import <Cocoa/Cocoa.h>
#import "SS_PreferencePaneProtocol.h"

@interface TwitterPreferencePaneController : NSObject <SS_PreferencePaneProtocol> 
{
	IBOutlet NSView *prefsView;
	IBOutlet NSButton *authButton;

	NSString *enableTwitterTooltip;
	NSString *nowplayingTooltip;
	NSString *musicMondayTooltip;
	
	NSString *tagSongTooltip;
}

#pragma mark -
#pragma mark properties

@property (readwrite, retain) NSString *enableTwitterTooltip;
@property (readwrite, retain) NSString *nowplayingTooltip;
@property (readwrite, retain) NSString *musicMondayTooltip;
@property (readwrite, retain) NSString *tagSongTooltip;


- (IBAction) twitterSucks: (id) sender;

@end
