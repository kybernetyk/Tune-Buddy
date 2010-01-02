/*!
 @header NSString+Additions
 @author	Jaroslaw Szpilewski
 @copyright Jaroslaw Szpilewski
 @abstract Contains additions to NSString
 */



//
//  NSString+Additions.h
//  DummyDownload
//
//  Created by jrk on 24/9/09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*!
 category that adds hashing methods to NSString
 */
@interface NSString (HashingAdditions)

/*!
 md5 hash value for the string
 */
- (NSString *) md5;

@end
