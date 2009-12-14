#import <Cocoa/Cocoa.h>
#import "SS_PreferencePaneProtocol.h"

@interface TwitterPreferencePaneController : NSObject <SS_PreferencePaneProtocol> {

    IBOutlet NSView *prefsView;
    
}

@end
