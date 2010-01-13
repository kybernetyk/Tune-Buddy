#import <Cocoa/Cocoa.h>
#import "SS_PreferencePaneProtocol.h"

@interface RegistrationPreferencePaneController : NSObject <SS_PreferencePaneProtocol> 
{

    IBOutlet NSView *prefsView;
    
	IBOutlet NSTextField *registeredToTextField;
	IBOutlet NSTextField *serialTextField;
	IBOutlet NSButton *registerButton;
	IBOutlet NSButton *buyButton;
	
	IBOutlet NSTextField *howtoLabel;
	
	
}

- (void) updateWindowWithRegistrationInfo;
- (IBAction) handleRegisterButton: (id) sender;
- (IBAction) handleBuyButton: (id) sender;


@end
