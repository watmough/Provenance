//
//  com.melissadata.m
//  Provenance
//
//  Created by Jonathan Watmough on 8/25/11.
//	Do whatever you want with this code.


#import "com.melissadata.h"

#pragma mark -
#pragma mark implements a simple scraper for info

#define OBJ(x) [NSNumber numberWithInt:[(x) hash]]  

@implementation comDotMelissaData

//--------------------------------------------------------------------------------
// init
//--------------------------------------------------------------------------------
- (id)init
{
	if (self = [super init]) {
		connectionDictionary = [[NSMutableDictionary alloc] init];
	}
	return self;
}

//--------------------------------------------------------------------------------
// dealloc
//--------------------------------------------------------------------------------
- (void)dealloc
{
	// cleanup
	for (NSURLConnection *connection in [connectionDictionary allKeys]) {
		[connection cancel];
		[connectionDictionary removeObjectForKey:connection];
	}
	[connectionDictionary release];
	[super dealloc];
}

#pragma mark -
#pragma mark JWDomainInfo protocol methods

//--------------------------------------------------------------------------------
// supportedAttributes
//--------------------------------------------------------------------------------
- (NSArray*)supportedAttributes
{
	// very basic implementation
	return [NSArray arrayWithObjects:@"IP Address",@"Domain",@"ISP",@"City",
			@"State or Region",@"Country",nil];
}

//--------------------------------------------------------------------------------
// resolveAddress
//--------------------------------------------------------------------------------
- (void)resolveAddress:(NSString*)address
					delegate:(id <JWDomainInfoDelegate>)callback
{
	// build the request into a dictionary
	NSMutableDictionary *resolverRequest = [NSMutableDictionary
											dictionaryWithObject:address forKey:@"address"];
	
	// Create the request.
	NSString *stringURL = [NSString stringWithFormat:
						   @"http://www.melissadata.com/lookups/iplocation.asp?ipaddress=%@",address];
	NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:stringURL]
											  cachePolicy:NSURLRequestUseProtocolCachePolicy
										  timeoutInterval:60.0];
	// create the connection with the request
	NSURLConnection *connection = [[[NSURLConnection alloc] initWithRequest:theRequest delegate:self] autorelease];
	if (connection) {
		// Create the NSMutableData to hold the received data.
		NSMutableData *receivedData = [NSMutableData data];
		[resolverRequest setObject:receivedData forKey:@"data"];
		[resolverRequest setObject:callback forKey:@"callback"];
		[resolverRequest setObject:connection forKey:@"connection"];
		[connectionDictionary setObject:resolverRequest forKey:OBJ(connection)];
	} else {
		// failed, inform caller
		NSDictionary *errorDict = [NSDictionary dictionaryWithObject:address forKey:@"address"];
		NSError * error = [NSError errorWithDomain:@"InternalError" code:0 userInfo:errorDict];
		[(NSObject*)callback performSelector:@selector(failedWithError:) withObject:error afterDelay:0.5];
	}
}

#pragma mark -
#pragma mark parse the returned info and notify callback

//--------------------------------------------------------------------------------
// filterString
// look for a line with a piece of text and take rest of line.
// add first occurrence to dictionary.
//--------------------------------------------------------------------------------
- (void)filterString:(NSString*)line forValue:(NSString*)key info:(NSMutableDictionary*)info
{
	NSRange search = [line rangeOfString:key];
	if (search.location==NSNotFound)
		return;
	
	NSString *value = [[[line substringFromIndex:search.location+search.length] 
						stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@""]
					   stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	if (value && [value length] && ![info objectForKey:key]) {
		[info setObject:value forKey:key];
	}	
}

//--------------------------------------------------------------------------------
// parse:
// parse an html response. the easiest way to parse this is just hack out the characters
// between ..html>$$$$$<html.. then parse them for useful data.
//--------------------------------------------------------------------------------
- (NSDictionary*)parse:(NSData*)data
{
	NSMutableArray *stack = [[[NSMutableArray alloc] init] autorelease];
	char buffer[2048];
	char *bufpos = buffer;
	const unsigned char *s = [data bytes];
	unsigned int l = [data length];
	BOOL printing = NO;
	while (l--) {
		if (*s=='\n' || *s=='\r') {
			s++;
			if (bufpos!=buffer) {
				*bufpos = '\0';
				[stack addObject:[NSString stringWithCString:buffer encoding:NSUTF8StringEncoding]];
				bufpos = buffer;
			}
			continue;
		}
		if (*s=='>') {
			printing = YES;
			s++;
			continue;
		}
		if (*s=='<') {
			printing = NO;
			s++;
			if (bufpos-buffer<2048) {
				*bufpos++ = ' ';
			}
			continue;
		}
		if (printing) {
			*bufpos++ = *s;
		}
		s++;
	}
	
	__block NSMutableDictionary *info = [[[NSMutableDictionary alloc] init] autorelease];
	[[[stack reverseObjectEnumerator] allObjects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
	 {
		 NSString *string = obj;
		 
		 [self filterString:string forValue:@"IP Address" info:info];
		 [self filterString:string forValue:@"Domain" info:info];
		 [self filterString:string forValue:@"ISP" info:info];
		 [self filterString:string forValue:@"Country" info:info];
		 [self filterString:string forValue:@"State or Region" info:info];
		 [self filterString:string forValue:@"City" info:info];
	 }];
	
	return info;
}

//--------------------------------------------------------------------------------
// callbackReturnedInfo
//--------------------------------------------------------------------------------
- (void)callbackReturnedInfo:(NSURLConnection*)connection
{
	NSDictionary *resolverRequest = [connectionDictionary objectForKey:OBJ(connection)];
	NSString *address = [resolverRequest objectForKey:@"address"];
	NSData *data = [resolverRequest objectForKey:@"data"];
	id <JWDomainInfoDelegate> callback = [resolverRequest objectForKey:@"callback"];
	
	NSDictionary *info = [self parse:data];
	[callback successAddress:address withAttributes:info];
}

#pragma mark -
#pragma mark NSURLConnection methods

//--------------------------------------------------------------------------------
// connection:didReceiveResponse
//--------------------------------------------------------------------------------
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	NSMutableData *receivedData = [[connectionDictionary objectForKey:OBJ(connection)] objectForKey:@"data"];
    [receivedData setLength:0];
}

//--------------------------------------------------------------------------------
// connection:didReceiveData
//--------------------------------------------------------------------------------
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	NSMutableData *receivedData = [[connectionDictionary objectForKey:OBJ(connection)] objectForKey:@"data"];
    [receivedData appendData:data];
}

//--------------------------------------------------------------------------------
// connection:didFailWithError
//--------------------------------------------------------------------------------
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	// do error, then cleanup - 
	NSString *address = [[connectionDictionary objectForKey:OBJ(connection)] objectForKey:@"address"];
	NSMutableDictionary * errorDict = [NSMutableDictionary dictionaryWithDictionary:[error userInfo]];
	[errorDict setObject:address forKey:@"address"];
	[[[connectionDictionary objectForKey:OBJ(connection)] objectForKey:@"callback"] 
	 performSelector:@selector(failedWithError:) withObject:error afterDelay:0.5];
	
	[connectionDictionary removeObjectForKey:OBJ(connection)];
}

//--------------------------------------------------------------------------------
// connectionDidFinishLoading
//--------------------------------------------------------------------------------
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // release the connection, and the data object
	[self callbackReturnedInfo:connection];
	[connectionDictionary removeObjectForKey:OBJ(connection)];
}


@end
