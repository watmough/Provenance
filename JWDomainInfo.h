//
//  JWDomainInfo.h
//  Provenance
//
//  Created by Jonathan Watmough on 8/25/11.
//	Do whatever you want with this code.


#import <Cocoa/Cocoa.h>

#pragma mark -
#pragma mark domain info callback and service protocol

// pass an object that supports this protocal when resolving an
// address or name.
@protocol JWDomainInfoDelegate

- (void)failedWithError:(NSError*)error;
- (void)successAddress:(NSString*)address
				  withAttributes:(NSDictionary*)attributes;
@end

// any given resolver will implement this protocol to support returning
// its supported properties, and to actually perform a resolution.
@protocol JWDomainInfo

- (NSDictionary*)supportedAttributes;
- (void)resolveAddress:(NSString*)address
					delegate:(id <JWDomainInfoDelegate>)delegate;
@end
