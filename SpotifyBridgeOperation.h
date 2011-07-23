//
//  SpotifyBridgeOperation.h
//  Tune Buddy
//
//  Created by jrk on 23/7/11.
//  Copyright 2011 Flux Forge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Spotify.h"
@interface SpotifyBridgeOperation : NSOperation 
{
//	iTunesApplication *iTunes;
	
	SpotifyApplication *spotify;
	
	NSString *currentDisplayString;
	NSString *playStatus;
	
	NSString *artistName;
	NSString *trackName;
	NSString *albumName;
	NSNumber *trackLength;
	NSDate *trackPlaybackStartTime;
	NSNumber *isStream;
	NSNumber *isPlaying;
	NSImage *albumArt;
	NSNumber *trackRating;
	NSNumber *trackPlayCount;
	
	NSInteger playbackPosition;
	
	id delegate;
	
	BOOL shouldMessage20PercentMark;
	BOOL didMessage20PercentMark;
}
#pragma mark -
#pragma mark properties

@property (readwrite, retain) NSString *playStatus;
@property (readwrite, assign) id delegate;
@property (readwrite, copy) NSString *currentDisplayString;
@property (readwrite, copy) NSNumber *trackRating;
@property (readwrite, copy) NSNumber *trackPlayCount;

@property (readwrite, copy) NSString *artistName;
@property (readwrite, copy) NSString *trackName;
@property (readwrite, copy) NSString *albumName;
@property (readwrite, copy) NSNumber *trackLength;
@property (readwrite, copy) NSDate *trackPlaybackStartTime;
@property (readwrite, copy) NSNumber *isStream;
@property (readwrite, copy) NSNumber *isPlaying;

@property (readwrite, copy) NSImage *albumArt;

- (void) fetchCurrentTrack;

@end