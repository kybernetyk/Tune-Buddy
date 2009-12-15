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
	
	id delegate;
}

@property (readwrite, assign) id delegate;
@property (readwrite, copy) NSString *currentDisplayString;

- (void) fetchCurrentTrackFromItunes;

@end
