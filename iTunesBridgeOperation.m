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
@synthesize playStatus;
@synthesize currentDisplayString;


@synthesize artistName;
@synthesize trackName;
@synthesize albumName;
@synthesize trackLength;
@synthesize trackPlaybackStartTime;
@synthesize isStream;
@synthesize isPlaying;
@synthesize trackRating;
@synthesize albumArt;
@synthesize trackPlayCount;

//returns the string that will be displayed/copied to pasteboard
- (void) fetchCurrentTrackFromItunes
{
	[self setCurrentDisplayString: nil];
	//NSString *playStatus = @"⌽ ";
	[self setPlayStatus: @"⌽ "];
	
	NSString *trackName = nil; //@"...";
	NSString *artistName = nil;// @"";
	NSString *albumName = nil;
	NSNumber *trackLength = nil;
	NSString *delimiter = nil;// @"";
	NSString *kind = nil;
	NSString *streamTitle = nil;
	iTunesEPlS playerState;
	
	BOOL trackExists = NO;
	BOOL isStream = NO;
	[self setIsPlaying: [NSNumber numberWithBool: NO]];

	
	if (!iTunes)
	{	
		@try
		{
			iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
			//[iTunes setTimeout: 10];
		//	[iTunes setDelegate: self];
			[iTunes retain];
			
			//NSLog(@"timeout: %d, %@",[iTunes timeout], iTunes);
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
		//NSLog(@"not running biatch!");
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
			{	
				trackName= [NSString stringWithString: trackName];
				[self setTrackName: trackName];
			}

			artistName = [currentTrack artist];
			if (artistName != nil)
			{	
				artistName = [NSString stringWithString: artistName];
				[self setArtistName: artistName];
			}
		
			
			albumName = [currentTrack album];
			if (albumName != nil)
			{	
				albumName = [NSString stringWithString: albumName];
				[self setAlbumName: albumName];
			}
			
			trackLength = [NSNumber numberWithDouble: [currentTrack duration]];
			[self setTrackLength: trackLength];
			
			[self setTrackRating: [NSNumber numberWithInteger: [currentTrack rating]]];
			[self setTrackPlayCount: [NSNumber numberWithInteger: [currentTrack playedCount]]];

			kind = [currentTrack kind];
			if (kind != nil)
				kind = [NSString stringWithString: kind];
		
			streamTitle = [iTunes currentStreamTitle];
			if (streamTitle != nil)
				streamTitle	= [NSString stringWithString: streamTitle];


/*			for (iTunesArtwork *artwork in [currentTrack artworks])
			{
				 NSLog(@"artwork: %@", [artwork data]);
				 [self setAlbumArt: [artwork data]];
			}*/
			
			//can't do this as it would copy the shit each loop run
			//			albumArt = [currentTrack artworks]
			
/*			NSDate *bla = [currentTrack playedDate];
			if (bla != nil)
				[self setTrackPlaybackStartTime: bla];*/
			
			playerState = [iTunes playerState];
			trackExists = YES;
			
			playbackPosition = [iTunes playerPosition];
			NSInteger len = [trackLength integerValue];
			NSInteger perc = (int)(100.0 / (float)len * (float)playbackPosition);
			
		//	NSLog(@"%i/%i = %i",playbackPosition,len, perc);
			
			
			if (!shouldMessage20PercentMark && !didMessage20PercentMark)
			{
				if (perc > 20)
				{
					shouldMessage20PercentMark = YES;
				}
			}
			
			/*	NSString *artistName;
			 NSString *trackName;
			 NSString *albumName;
			 NSNumber *trackLength;
*/
			
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

	[self setIsStream: [NSNumber numberWithBool: isStream]];
	
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
		[self setPlayStatus: @"♫ "];
		
		if (isStream)
			[self setPlayStatus: @"☢ "];
		
		[self setIsPlaying: [NSNumber numberWithBool: YES]];
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
	NSString *previousArtistName = nil;
	NSString *previousTrackName = nil;
	NSString *previousAlbumName = nil;

	didMessage20PercentMark = NO;
	shouldMessage20PercentMark = NO;
	
	
	int poolKillCounter = 0;
	
	double resolution = 0.75;
//	BOOL endRunLoop = NO;
	//BOOL isRunning;
	
	NSPort *aPort = [NSPort port];
    [[NSRunLoop currentRunLoop] addPort:aPort forMode:NSDefaultRunLoopMode];
	
	NSLog (@"current thread: %@",[NSThread currentThread]);

	NSAutoreleasePool *localPool = [[NSAutoreleasePool alloc] init];	
	[self setTrackPlaybackStartTime: [NSDate date]];
	while (![self isCancelled])
	{
//		if (currentDisplayString)
		{
			[previousDisplayString release];
			previousDisplayString = [currentDisplayString retain];
			
			[previousArtistName release];
			previousArtistName = [artistName retain];
			
			[previousTrackName release];
			previousTrackName = [trackName retain];
			
			[previousAlbumName release];
			previousAlbumName = [albumName retain];
		}
		
		[self fetchCurrentTrackFromItunes];
	

		
		if (![currentDisplayString isEqualToString: previousDisplayString] || !previousDisplayString || !currentDisplayString)
		{
			NSLog(@"current track changed to: %@ from %@",currentDisplayString, previousDisplayString);
			
			
			
			//NSLog(@"length: %@",[self trackLength]);
			/*
			 NSString *artistName;
			 NSString *trackName;
			 NSString *albumName;
			 NSNumber *trackLength;
			 NSDate *trackPlaybackStartTime;
*/
			//let us retain this here - we don't know when it might die - the delegate will release it >.<

			
			if (![previousArtistName isEqualToString: artistName] ||
				![previousTrackName isEqualToString: trackName] ||
				![previousAlbumName isEqualToString: albumName])
			{
				didMessage20PercentMark = NO;
				shouldMessage20PercentMark = NO;
				//[self setTrackPlaybackStartTime: [NSDate dateWithTimeIntervalSince1970: [[NSDate date] timeIntervalSince1970] - playbackPosition]];
				
				[self setTrackPlaybackStartTime: [NSDate date]];
			}

			//nils don't go into a dict!
			if (![self artistName])
				[self setArtistName: @""];
			
			if (![self trackName])
				[self setTrackName: @""];
			
			if (![self albumName])
				[self setAlbumName: @""];

			NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
								  [NSString stringWithString: currentDisplayString], @"displayString",
								  [NSString stringWithString: playStatus], @"displayStatus", 
								  
								  [NSString stringWithString: [self artistName]], @"artistName",
								  [NSString stringWithString: [self trackName]], @"trackName",
								  [NSString stringWithString: [self albumName]], @"albumName",
								  [NSNumber numberWithDouble: [[self trackLength] doubleValue]], @"trackLength",
								    [NSNumber numberWithBool: [[self isStream] boolValue]], @"isStream",
								    [NSNumber numberWithBool: [[self isPlaying] boolValue]], @"isPlaying",
								  [NSDate dateWithTimeIntervalSince1970: [[self trackPlaybackStartTime] timeIntervalSince1970]] , @"trackPlaybackStartTime",
									[NSNumber numberWithInteger: [[self trackRating] integerValue]], @"trackRating",
									[NSNumber numberWithInteger: [[self trackPlayCount] integerValue]], @"trackPlayCount",
								  nil];
			
//			[dict retain];
			
			//get artwork and pass it to the dict
		/*	@try
			{
				if ([iTunes isRunning])
				{				
					iTunesTrack *currentTrack = [iTunes currentTrack];
					
					for (iTunesArtwork *artwork in [currentTrack artworks])
					{
						NSLog(@"artwork: %@", [artwork data]);
						[self setAlbumArt: [artwork data]];
						[dict setObject: [self albumArt] forKey: @"albumArt"];
					}
					
				}
			}
			@catch (NSException *e) 
			{
				NSLog(@"#3 Exception:%@ Reason: %@ Callstack: %@ userInfo: %@",e, [e reason], [e callStackSymbols],[e userInfo] );
				
			}*/

			NSLog(@"dict: %@",dict);

			
			[delegate performSelectorOnMainThread:@selector(iTunesTrackDidChangeTo:) withObject: dict waitUntilDone: YES];
			[dict release];
		}

		if (shouldMessage20PercentMark && !didMessage20PercentMark)
		{
			//nils don't go into a dict!
			if (![self artistName])
				[self setArtistName: @""];
			
			if (![self trackName])
				[self setTrackName: @""];
			
			if (![self albumName])
				[self setAlbumName: @""];
			
			
			NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys: 
								  [NSString stringWithString: currentDisplayString], @"displayString",
								  [NSString stringWithString: playStatus], @"displayStatus", 
								  
								  [NSString stringWithString: [self artistName]], @"artistName",
								  [NSString stringWithString: [self trackName]], @"trackName",
								  [NSString stringWithString: [self albumName]], @"albumName",
								  [NSNumber numberWithDouble: [[self trackLength] doubleValue]], @"trackLength",
								  [NSNumber numberWithBool: [[self isStream] boolValue]], @"isStream",
								    [NSNumber numberWithBool: [[self isPlaying] boolValue]], @"isPlaying",
								  [NSDate dateWithTimeIntervalSince1970: [[self trackPlaybackStartTime] timeIntervalSince1970]] , @"trackPlaybackStartTime",
								  nil];
		//	[dict retain];
			[delegate performSelectorOnMainThread:@selector(iTunesTrackDidPass20PercentMark:) withObject: dict waitUntilDone: YES];
			didMessage20PercentMark = YES;
			
			[dict release];
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
		
		usleep(kRefreshFrequencyInMicroseconds/2.0);
		NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithObjectsAndKeys: 
									 [NSString stringWithString: currentDisplayString], @"displayString",
									 [NSString stringWithString: playStatus], @"displayStatus", 
									 
									 [NSString stringWithString: [self artistName]], @"artistName",
									 [NSString stringWithString: [self trackName]], @"trackName",
									 [NSString stringWithString: [self albumName]], @"albumName",
									 [NSNumber numberWithDouble: [[self trackLength] doubleValue]], @"trackLength",
									 [NSNumber numberWithBool: [[self isStream] boolValue]], @"isStream",
									 [NSNumber numberWithBool: [[self isPlaying] boolValue]], @"isPlaying",
									 [NSDate dateWithTimeIntervalSince1970: [[self trackPlaybackStartTime] timeIntervalSince1970]] , @"trackPlaybackStartTime",
									 [NSNumber numberWithInteger: [[self trackRating] integerValue]], @"trackRating",
									 [NSNumber numberWithInteger: [[self trackPlayCount] integerValue]], @"trackPlayCount",
									 nil];
		[delegate performSelectorOnMainThread:@selector(bridgePing:) withObject: dict waitUntilDone: YES];
		[dict release];
		usleep(kRefreshFrequencyInMicroseconds/2.0);
	}
	
	NSLog(@"LOL ITUNES DIEDDD!");
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
