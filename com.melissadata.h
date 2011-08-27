//
//  com.melissdata.h
//  Provenance
//
//  Created by Jonathan Watmough on 8/25/11.
//	Do whatever you want with this code.

#import <Cocoa/Cocoa.h>
#import "JWDomainInfo.h"

@interface comDotMelissaData : NSObject <JWDomainInfo>
{

	// private, track all the addresses we've been asked to resolve
	// keyed by connection, so we can have multiple connections.
	NSMutableDictionary *connectionDictionary;
	
}

// methods
- (NSArray*)supportedAttributes;
- (void)resolveAddress:(NSString*)address
					delegate:(id <JWDomainInfoDelegate>)delegate;

@end
