//
//  FMEngine.h
//  LastFMAPI
//
//  Created by Nicolas Haunold on 4/26/09.
//  Copyright 2009 Tapolicious Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSString+FMEngine.h"

#define _LASTFM_API_KEY_ @"770f2543649dd5aa57e4a65b8c192a87"
#define _LASTFM_SECRETK_ @"c5cd383b19bed4e43e448dd1115a627a"
#define _LASTFM_BASEURL_ @"http://ws.audioscrobbler.com/2.0/"

// Comment the next line to use XML
#define _USE_JSON_ 1

#define POST_TYPE	@"POST"
#define GET_TYPE	@"GET"

@class FMEngine;

@interface FMEngine : NSObject {
	NSMutableData *receivedData;
	NSMutableDictionary *connections;
}


- (NSString *)generateAuthTokenFromUsername:(NSString *)username password:(NSString *)password;
- (NSString *)generateSignatureFromDictionary:(NSDictionary *)dict;
- (NSString *)generatePOSTBodyFromDictionary:(NSDictionary *)dict;
- (NSURL *)generateURLFromDictionary:(NSDictionary *)dict;

- (void)performMethod:(NSString *)method withTarget:(id)target withParameters:(NSDictionary *)params andAction:(SEL)callback useSignature:(BOOL)useSig httpMethod:(NSString *)httpMethod;
- (NSData *)dataForMethod:(NSString *)method withParameters:(NSDictionary *)params useSignature:(BOOL)useSig httpMethod:(NSString *)httpMethod error:(NSError *)err;

- (NSString *) scrobbleAuthToken: (NSNumber *) timestamp;

@end
