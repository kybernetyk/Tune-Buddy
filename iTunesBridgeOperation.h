//
//  iTunesBridgeOperation.h
//  TuneStat
//
//  Created by jrk on 15/12/09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iTunes.h"

@interface iTunesBridgeOperation : NSOperation 
{
	iTunesApplication *iTunes;
	
	NSString *currentDisplayString;
	NSString *playStatus;
	
	id delegate;
}
#pragma mark -
#pragma mark properties

@property (readwrite, retain) NSString *playStatus;
@property (readwrite, assign) id delegate;
@property (readwrite, copy) NSString *currentDisplayString;

- (void) fetchCurrentTrackFromItunes;

@end
