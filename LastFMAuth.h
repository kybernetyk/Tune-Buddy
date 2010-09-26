//
//  LastFMAuth.h
//  Tune Buddy
//
//  Created by jrk on 17/5/10.
//  Copyright 2010 Flux Forge. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LastFMAuth : NSObject 
{
	NSString *_secretKey;
}
+(LastFMAuth *) sharedLastFMAuth;
- (void) reset;

- (NSString *) secretKey;
- (NSString *) username;
- (NSString *) password;

@end
