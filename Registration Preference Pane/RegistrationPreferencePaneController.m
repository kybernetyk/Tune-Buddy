#import "RegistrationPreferencePaneController.h"

@implementation RegistrationPreferencePaneController


+ (NSArray *)preferencePanes
{
    return [NSArray arrayWithObjects:[[[RegistrationPreferencePaneController alloc] init] autorelease], nil];
}


- (NSView *)paneView
{
    BOOL loaded = YES;
    
    if (!prefsView) {
        loaded = [NSBundle loadNibNamed:@"RegistrationPreferencePaneView" owner:self];
    }
    
    if (loaded) {
        return prefsView;
    }
    
    return nil;
}


- (NSString *)paneName
{
    return @"Registration";
}


- (NSImage *)paneIcon
{
    return [[[NSImage alloc] initWithContentsOfFile:
        [[NSBundle bundleForClass:[self class]] pathForImageResource:@"Registration_Prefs.png"]
        ] autorelease];
}


- (NSString *)paneToolTip
{
    return @"Registration Preferences";
}


- (BOOL)allowsHorizontalResizing
{
    return NO;
}


- (BOOL)allowsVerticalResizing
{
    return NO;
}

#pragma mark -
#pragma mark implementation
- (void) didShow: (id) sender
{
	NSLog(@"did show!");
	[self updateWindowWithRegistrationInfo];
}

- (void) updateWindowWithRegistrationInfo
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSString *registeredTo = [defaults stringForKey: @"registeredTo"];
	NSString *serial = [defaults stringForKey: @"serial"];
	
	
	if ([[NSApp delegate] isRegistered])
	{
		[registeredToTextField setStringValue: registeredTo];
		[serialTextField setStringValue: serial];
		
		[registeredToTextField setEditable: NO];
		[serialTextField setEditable: NO];
		
		[registerButton setEnabled: NO];
		[buyButton setEnabled: NO];
		
		//[howtoLabel setHidden: YES];
		[howtoLabel setStringValue: @"This copy of Tune Buddy is registered. Thank you!"];
	}
	else
	{

	
	}
	
}


- (IBAction) handleRegisterButton: (id) sender
{
	NSLog(@"register button!");
	
	//WNEB-FYNJ-FMCV-YRJF-XVXX
	
	NSString *name = [registeredToTextField stringValue];
	NSString *serial = [serialTextField stringValue];
	
	[[NSApp delegate] registerForName: name andSerial: serial];
	[[NSApp delegate] checkRegistration];
	[self updateWindowWithRegistrationInfo];
	
	if ([[NSApp delegate] isRegistered])
	{
		NSAlert *al = [NSAlert alertWithMessageText:@"Registration Successful" defaultButton:@"Ok" alternateButton: nil otherButton: nil informativeTextWithFormat:@"The registration was successful. Thank you for registering Tune Buddy!"];
		[al setAlertStyle: NSInformationalAlertStyle];
		[al runModal];
	}
	else 
	{
		NSAlert *al = [NSAlert alertWithMessageText:@"Registration Failed" defaultButton:@"Ok" alternateButton: nil otherButton: nil informativeTextWithFormat:@"The registration failed. Check if you entered everything correctly and try again.\n\nShould the registration fail again contact the support: support@appslide.net"];
		[al setAlertStyle: NSWarningAlertStyle];
		[al runModal];
		
	}
	
}

- (IBAction) handleBuyButton: (id) sender
{
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://www.fluxforge.com/tune-buddy/"]];
	 
 }

@end
