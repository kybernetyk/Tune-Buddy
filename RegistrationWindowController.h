//
//  RegistrationWindowController.h
//  itunes control
//
//  Created by jrk on 1/11/09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RegistrationWindowController : NSWindowController 
{
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
