//
//  RegistrationWindowController.m
//  itunes control
//
//  Created by jrk on 1/11/09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import "RegistrationWindowController.h"


@implementation RegistrationWindowController

- (void) updateWindowWithRegistrationInfo
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSString *registeredTo = [defaults stringForKey: @"registeredTo"];
	NSString *serial = [defaults stringForKey: @"serial"];
	
	
	if ([[NSApp delegate] isRegistered])
	{
		[[self window] setTitle: @"Tune Stat (registered)"];
		[registeredToTextField setStringValue: registeredTo];
		[serialTextField setStringValue: serial];

		[registeredToTextField setEditable: NO];
		[serialTextField setEditable: NO];
		
		[registerButton setEnabled: NO];
		[buyButton setEnabled: NO];
		
		[howtoLabel setHidden: YES];
	}
	else
	{
		[[self window] setTitle: @"Tune Stat (unregistered)"];
	}
	
}


- (IBAction) handleRegisterButton: (id) sender
{
	NSLog(@"register button!");
	
	//WNEB-FYNJ-FMCV-YRJF-XVXX
	
	[[NSApp delegate] registerForName:  [registeredToTextField stringValue] andSerial: [serialTextField stringValue]];
	[[NSApp delegate] checkRegistration];
	[self updateWindowWithRegistrationInfo];
	
	if ([[NSApp delegate] isRegistered])
	{
		NSAlert *al = [NSAlert alertWithMessageText:@"Registration Successful" defaultButton:@"Ok" alternateButton: nil otherButton: nil informativeTextWithFormat:@"The registration was successful. Thank you for registering Tune Stat!"];
		[al runModal];
	}
	else 
	{
		NSAlert *al = [NSAlert alertWithMessageText:@"Registration Failed" defaultButton:@"Ok" alternateButton: nil otherButton: nil informativeTextWithFormat:@"The registration failed. Check if you entered everything correctly and try again.\n\nShould the registration fail again contact the support: support@fluxforge.com"];
		[al runModal];

	}

}

- (IBAction) handleBuyButton: (id) sender
{
	
}


@end
