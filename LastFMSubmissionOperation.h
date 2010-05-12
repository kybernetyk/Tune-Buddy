//
//  LastFMSubmissionOperation.h
//  Tune Buddy
//
//  Created by jrk on 12/5/10.
//  Copyright 2010 Flux Forge. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LastFMSubmissionOperation : NSOperation 
{
	NSArray *dictsToSubmit;
	NSString *username;
	NSString *password;
	
	id delegate;
}

@property (readwrite, copy) NSArray *dictsToSubmit;

@property (assign) id delegate;
@property (readwrite, copy) NSString *username;
@property (readwrite, copy) NSString *password;


@end
