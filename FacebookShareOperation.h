//
//  FacebookShareOperation.h
//  Tune Buddy
//
//  Created by jrk on 26/9/10.
//  Copyright 2010 Flux Forge. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface FacebookShareOperation : NSOperation 
{
	id delegate;
	NSString *message;
	NSImage *albumArt;
	
	NSString *artworkURL;
	NSString *trackviewURL;
	
	NSString *trackArtist;
	NSString *trackName;
	NSString *albumName;
	NSNumber *trackRating;
	NSNumber *trackPlayCount;
}

@property (readwrite, assign) id delegate;
@property (readwrite, copy) NSString *message;
@property (readwrite, retain) NSImage *albumArt;
@property (readwrite, copy) NSNumber *trackPlayCount;
@property (readwrite, copy) NSString *artworkURL;
@property (readwrite, copy) NSString *trackviewURL;

@property (readwrite, copy) NSString *trackArtist;
@property (readwrite, copy) NSString *trackName;
@property (readwrite, copy) NSString *albumName;

@property (readwrite, copy) NSNumber *trackRating;
@end
