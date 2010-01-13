#import <Cocoa/Cocoa.h>
#import "SS_PreferencePaneProtocol.h"

@interface TwitterPreferencePaneController : NSObject <SS_PreferencePaneProtocol> 
{

    IBOutlet NSView *prefsView;

    IBOutlet NSTextField *username;
	IBOutlet NSTextField *password;
	
	NSString *enableTwitterTooltip;
	NSString *nowplayingTooltip;
	NSString *musicMondayTooltip;
	
	NSString *twitterUsernameTooltip;
	NSString *twitterPasswordTooltip;	
}

#pragma mark -
#pragma mark properties

@property (readwrite, retain) NSString *enableTwitterTooltip;
@property (readwrite, retain) NSString *nowplayingTooltip;
@property (readwrite, retain) NSString *musicMondayTooltip;
@property (readwrite, retain) NSString *twitterUsernameTooltip;
@property (readwrite, retain) NSString *twitterPasswordTooltip;


- (IBAction) usernameChanged: (id) sender;
- (IBAction) passwordChanged: (id) sender;

@end
