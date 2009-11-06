//
//  NSString+Search.m
//  DummyDownload
//
//  Created by jrk on 24/9/09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import "NSString+Search.h"


@implementation NSString (SearchingAdditions)

- (BOOL)containsString:(NSString *)aString 
{
    return [self containsString:aString ignoringCase:NO];
}

- (BOOL)containsString:(NSString *)aString ignoringCase:(BOOL)flag 
{
    unsigned mask = (flag ? NSCaseInsensitiveSearch : 0);
    return [self rangeOfString:aString options:mask].length > 0;
}

@end


@implementation NSString (rot13)

+ (NSString *)rot13:(NSString *)theText 
{
    NSMutableString *holder = [[NSMutableString alloc] init];
    unichar theChar;
    int i;
    
    for(i = 0; i < [theText length]; i++) {
        theChar = [theText characterAtIndex:i];
        if(theChar <= 122 && theChar >= 97) {
            if(theChar + 13 > 122)
                theChar -= 13;
            else 
                theChar += 13;
            [holder appendFormat:@"%C", (char)theChar];
            
            
        } else if(theChar <= 90 && theChar >= 65) {
            if((int)theChar + 13 > 90)
                theChar -= 13;
            else
                theChar += 13;
            
            [holder appendFormat:@"%C", theChar];
			
        } else {
            [holder appendFormat:@"%C", theChar];
        }
    }
    
    return [NSString stringWithString:holder];
}

@end