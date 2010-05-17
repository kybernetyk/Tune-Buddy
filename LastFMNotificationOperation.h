//
//  LastFMNotificationOperation.h
//  Tune Buddy
//
//  Created by jrk on 14/5/10.
//  Copyright 2010 Flux Forge. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LastFMNotificationOperation : NSOperation 
{
	id delegate;
	
	
	NSString *artistName;
	NSString *trackName;
	NSString *albumName;
	NSNumber *trackLength;
	NSDate *trackPlaybackStartTime;
	
}


@property (assign) id delegate;


@property (readwrite, copy) NSString *artistName;
@property (readwrite, copy) NSString *trackName;
@property (readwrite, copy) NSString *albumName;
@property (readwrite, copy) NSNumber *trackLength;
@property (readwrite, copy) NSDate *trackPlaybackStartTime;

@end
