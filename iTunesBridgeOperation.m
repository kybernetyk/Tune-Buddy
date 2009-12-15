//
//  iTunesBridgeOperation.m
//  TuneStat
//
//  Created by jrk on 15/12/09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import "iTunesBridgeOperation.h"

#define kRefreshFrequencyInMicroseconds 500000

@implementation iTunesBridgeOperation
@synthesize delegate;
@synthesize currentDisplayString;


//returns the string that will be displayed/copied to pasteboard
- (void) fetchCurrentTrackFromItunes
{
	NSString *playStatus = @"⌽ ";
	NSString *trackName = nil; //@"...";
	NSString *artistName = nil;// @"";
	NSString *delimiter = nil;// @"";
	NSString *kind = nil;
	NSString *streamTitle = nil;
	iTunesEPlS playerState;
	
	BOOL trackExists = NO;
	BOOL isStream = NO;
	
	
	if (!iTunes)
		iTunes = [[SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"] retain];
	
	if (![iTunes isRunning])
	{	
		[self setCurrentDisplayString: [NSString stringWithFormat:@"%@",playStatus]];
		return;
	}
	
	iTunesTrack *currentTrack = [iTunes currentTrack];
		
	
	if ([currentTrack exists] && [iTunes isRunning])
	{
		if ([currentTrack name])
			trackName	= [NSString stringWithString: [currentTrack name]];

		if ([currentTrack artist])
			artistName = [NSString stringWithString: [currentTrack artist]];
		
		if ([currentTrack kind])
			kind = [NSString stringWithString: [currentTrack kind]];
		
		if ([iTunes currentStreamTitle])
			streamTitle	= [NSString stringWithString: [iTunes currentStreamTitle]];

		playerState = [iTunes playerState];
		trackExists = YES;
		
	}
	else
	{
		[self setCurrentDisplayString: [NSString stringWithFormat:@"%@",playStatus]];
		return;
	}
	
	
	if ([kind containsString: @"stream" ignoringCase: YES])
		isStream = YES;
	
	if (trackExists)
	{
		delimiter = @" - ";
		if ([trackName isEqualToString:@""])
		{	
			trackName = nil;
			delimiter = nil;
		}
		if ([artistName isEqualToString:@""])
		{	
			artistName = nil;
			delimiter = nil;
		}
		
		
		/*
		 why are we doing it here and not earlier as we know if it it a stream or not?
		 because many stream providers fuck up their title tags and put their station's name
		 into the stream-title. the currently played song title is then stored as a comment (or is not sent at all).
		 so we try to get the real track title here
		 */
		if (isStream)
		{
			if (streamTitle && ![streamTitle isEqualToString: @""])
			{				
				BOOL showRadioStation = NO;
				
				if (showRadioStation)
				{
					artistName = trackName;
					trackName = streamTitle;
					delimiter = @": ";
				}
				else
				{
					artistName = streamTitle;
					trackName = nil;
					delimiter = nil;
				}
				
			}
			else
			{
				//NSLog(@"no stream title!");
			}
		}
	}
	
	
	//	iTunesEPlSStopped = 'kPSS',
	//	iTunesEPlSPlaying = 'kPSP',
	//	iTunesEPlSPaused = 'kPSp',
	//	iTunesEPlSFastForwarding = 'kPSF',
	//	iTunesEPlSRewinding = 'kPSR'
	
	if (playerState == iTunesEPlSPlaying)
	{	
		playStatus = @"♫ ";
		
		if (isStream)
			playStatus = @"☢ ";
	}
	
	if (!artistName && !trackName)
	{
		[self setCurrentDisplayString: [NSString stringWithFormat:@"%@",playStatus]];		
		return;
	}
	
	if (!artistName)
	{
		[self setCurrentDisplayString: [NSString stringWithFormat:@"%@%@",playStatus,trackName]];
		return;
	}
	
	if (!trackName)
	{
		[self setCurrentDisplayString: [NSString stringWithFormat:@"%@%@",playStatus,artistName]];
		return;
	}
	
	
	[self setCurrentDisplayString: [NSString stringWithFormat:@"%@%@%@%@",playStatus,artistName,delimiter,trackName]];
	return;
	
}


- (void) main
{
	NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];
	NSString *previousDisplayString = nil;
	
	
	NSAutoreleasePool *localPool = [[NSAutoreleasePool alloc] init];	
	int poolKillCounter = 0;
	
	while (![self isCancelled])
	{
		[previousDisplayString release];
		previousDisplayString = [currentDisplayString retain];
		
		[self fetchCurrentTrackFromItunes];
	
		if (![currentDisplayString isEqualToString: previousDisplayString])
		{
			//NSLog(@"current track changed to: %@",currentDisplayString);
			[delegate performSelectorOnMainThread:@selector(iTunesTrackDidChangeTo:) withObject: currentDisplayString waitUntilDone: YES];
			
		}

		poolKillCounter ++;
		if (poolKillCounter >= 10)
		{
			[localPool release];
			localPool = [[NSAutoreleasePool alloc] init];
			poolKillCounter = 0;
		}
		
		usleep(kRefreshFrequencyInMicroseconds);
	}
	
	[thePool release];	
}

@end
