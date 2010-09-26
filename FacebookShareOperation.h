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
}

@property (readwrite, assign) id delegate;
@property (readwrite, copy) NSString *message;

@end
