//
//  LastFMScrobbler.h
//  Tune Buddy
//
//  Created by jrk on 15/4/10.
//  Copyright 2010 Flux Forge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMEngine.h"

@interface LastFMScrobbler : NSObject 
{
	NSString *artistName;
	NSString *trackName;
	NSString *albumName;
	NSNumber *trackLength;
	NSDate *trackPlaybackStartTime;
	
	NSMutableData *tempData;
	
	NSString *username;
	NSString *password;
	

	
	id delegate;
}

@property (assign) id delegate;

@property (readwrite, copy) NSString *username;
@property (readwrite, copy) NSString *password;

@property (readwrite, copy) NSString *artistName;
@property (readwrite, copy) NSString *trackName;
@property (readwrite, copy) NSString *albumName;
@property (readwrite, copy) NSNumber *trackLength;
@property (readwrite, copy) NSDate *trackPlaybackStartTime;



- (void) performNotification;
- (void) performSubmission;

@end
