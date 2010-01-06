//
//  iTunesBridgeOperation.m
//  TuneStat
//
//  Created by jrk on 15/12/09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import "iTunesBridgeOperation.h"
#import "NSString+Search.h"

#define kRefreshFrequencyInMicroseconds 500000

@implementation iTunesBridgeOperation
@synthesize delegate;
@synthesize currentDisplayString;


//returns the string that will be displayed/copied to pasteboard
- (void) fetchCurrentTrackFromItunes
{
	[self setCurrentDisplayString: nil];
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
	{	
		@try
		{
			iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
			[iTunes setTimeout: 10];
		//	[iTunes setDelegate: self];
			[iTunes retain];
		}
		@catch(NSException *e)
		{
			NSLog(@"#1 Exception:%@ Reason: %@ Callstack: %@ userInfo: %@",e, [e reason], [e callStackSymbols],[e userInfo] );
			[self setCurrentDisplayString: [NSString stringWithFormat:@"%@",playStatus]];
			return;

		}
		

	}
	
	if (![iTunes isRunning])
	{	
		[self setCurrentDisplayString: [NSString stringWithFormat:@"%@",playStatus]];
		return;
	}
	
	iTunesTrack *currentTrack = nil;
	@try
	{
		currentTrack = [[iTunes currentTrack] get];
	}
	@catch(NSException *e)
	{
		NSLog(@"#2 Exception:%@ Reason: %@ Callstack: %@ userInfo: %@",e, [e reason], [e callStackSymbols],[e userInfo] );
		[self setCurrentDisplayString: [NSString stringWithFormat:@"%@",playStatus]];
		return;

	}
		
	
	if ([currentTrack exists] && [iTunes isRunning])
	{
		@try 
		{
			trackName = [currentTrack name];
			if (trackName != nil)
				trackName= [NSString stringWithString: trackName];

			artistName = [currentTrack artist];
			if (artistName != nil)
				artistName = [NSString stringWithString: artistName];
		
			kind = [currentTrack kind];
			if (kind != nil)
				kind = [NSString stringWithString: kind];
		
			streamTitle = [iTunes currentStreamTitle];
			if (streamTitle != nil)
				streamTitle	= [NSString stringWithString: streamTitle];

			playerState = [iTunes playerState];
			trackExists = YES;
		}
		@catch (NSException *e) 
		{
			NSLog(@"#3 Exception:%@ Reason: %@ Callstack: %@ userInfo: %@",e, [e reason], [e callStackSymbols],[e userInfo] );
			
			
			NSLog(@"name: %@", trackName);
			NSLog(@"artist: %@", artistName);
			NSLog(@"kind: %@", kind);
			NSLog(@"stream: %@", streamTitle);
			
			[self setCurrentDisplayString: [NSString stringWithFormat:@"%@",playStatus]];
			return;
		}
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
	
	
	int poolKillCounter = 0;
	
	double resolution = 0.75;
//	BOOL endRunLoop = NO;
	//BOOL isRunning;
	
	NSPort *aPort = [NSPort port];
    [[NSRunLoop currentRunLoop] addPort:aPort forMode:NSDefaultRunLoopMode];
	
	NSLog (@"current thread: %@",[NSThread currentThread]);

	NSAutoreleasePool *localPool = [[NSAutoreleasePool alloc] init];	
	while (![self isCancelled])
	{
		[previousDisplayString release];
		previousDisplayString = [currentDisplayString retain];
		
		[self fetchCurrentTrackFromItunes];
	
		if (![currentDisplayString isEqualToString: previousDisplayString])
		{
			NSLog(@"current track changed to: %@",currentDisplayString);
			[delegate performSelectorOnMainThread:@selector(iTunesTrackDidChangeTo:) withObject: currentDisplayString waitUntilDone: YES];

		}

		NSDate* next = [NSDate dateWithTimeIntervalSinceNow:resolution];
		/*isRunning =*/ [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:next];
		//NSLog(@"%i", isRunning);
		
		
		poolKillCounter ++;
		if (poolKillCounter >= 20) //after 10 seconds
		{
			[localPool release];
			localPool = [[NSAutoreleasePool alloc] init];
			poolKillCounter = 0;
			
			//reset itunes to reconnect 
			//[iTunes release];
			//iTunes = nil;
		}
		
		//usleep(kRefreshFrequencyInMicroseconds);
	//	NSLog(@"tick");
	}
	[iTunes release];
	[thePool release];	
}



- (void)eventDidFail:(const AppleEvent *)event withError:(NSError *)error
{
	NSLog (@"current  error thread: %@",[NSThread currentThread]);
	NSLog(@"An Epple Event failed: %@, %@",[error localizedDescription], [error userInfo]);

	//[iTunes autorelease];
//	iTunes = nil;
	
}

@end
