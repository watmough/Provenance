//
//  ProvenanceAppDelegate.m
//  Provenance
//
//  Created by Jonathan Watmough on 8/25/11.
//	Do whatever you want with this code.


#import "JWDomainInfo.h"
#import "ProvenanceAppDelegate.h"
#import "com.melissadata.h"

@implementation ProvenanceAppDelegate

@synthesize mailText;
@synthesize contextLines;
@synthesize addresses;
@synthesize info;

@synthesize window;
@synthesize tableView;
@synthesize dropTarget;

//--------------------------------------------------------------------------------
// applicationDidFinishLaunching:
//--------------------------------------------------------------------------------
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application
	
	// create lookup object
	lookup = [[comDotMelissaData alloc] init];
	
	// setup table view
	contextLines = [[NSMutableDictionary alloc] init];
	addresses = [[NSMutableArray alloc] init];
	info = [[NSMutableArray alloc] init];
	[tableView setDataSource:self];
	[tableView reloadData];
	
	// add image to drop target
	[dropTarget setImage:[NSImage imageNamed:@"kitchenaid.jpg"]];
	[dropTarget setHidden:YES];
	
	// register for dragged types
	NSArray *types = [NSArray arrayWithObject:NSPasteboardTypeString];
	[window registerForDraggedTypes:types];
	[window setDelegate:self];
}

#pragma mark -
#pragma mark JWDomainInfoCallback

//--------------------------------------------------------------------------------
// failedWithError
//--------------------------------------------------------------------------------
- (void)failedWithError:(NSError*)error
{
	NSLog(@"failure, error: %@",[error description]);
}

//--------------------------------------------------------------------------------
// successAddress:withAttributes
//--------------------------------------------------------------------------------
- (void)successAddress:(NSString*)address
		withAttributes:(NSDictionary*)attributes
{
	NSLog(@"success, attributes: %@",[attributes description]);
	
	NSString *infoString = [NSString stringWithFormat:@"DOMAIN: %@ ISP: %@ CITY: %@ REGION: %@ COUNTRY: %@",
							[attributes objectForKey:@"Domain"],
							[attributes objectForKey:@"ISP"],
							[attributes objectForKey:@"City"],
							[attributes objectForKey:@"State or Region"],
							[attributes objectForKey:@"Country"]];
	
	// populate appropriate row of table view
	NSInteger index = [addresses indexOfObject:address];
	[info replaceObjectAtIndex:index withObject:[NSString stringWithFormat:@"%@\r\n%@",
												 [contextLines objectForKey:address],infoString]];
	[tableView reloadData];
}


#pragma mark -
#pragma mark Fluff

//--------------------------------------------------------------------------------
// hideDropTarget
//--------------------------------------------------------------------------------
- (void)hideDropTarget:(BOOL)hide
{
	[dropTarget setHidden:hide];
}

#pragma mark -
#pragma mark Table View Methods

//--------------------------------------------------------------------------------
// processMailText
// parse out any ipv4 addresses and resolve them
//--------------------------------------------------------------------------------
- (void)processMailText
{
	// clear out table view
	[contextLines removeAllObjects];
	[addresses removeAllObjects];
	[info removeAllObjects];
	[tableView reloadData];
	
	// character set with characters outside 0-9.
	NSCharacterSet *nonIP = [[NSCharacterSet characterSetWithCharactersInString:@"0987654321."] invertedSet];
	NSCharacterSet *period= [NSCharacterSet characterSetWithCharactersInString:@"."];
	
	// dictionary of ip addresses found so far
	__block NSMutableDictionary *alreadySeen = [[[NSMutableDictionary alloc] init] autorelease];
	
	// break mail text into lines
	[mailText enumerateLinesUsingBlock:^(NSString *line, BOOL *stop)
	{
		// break lines into "text [xxx.xxx.xxx.xxx|*com|*net|*gov]"
		NSArray *components = [line componentsSeparatedByCharactersInSet:
							   [NSCharacterSet characterSetWithCharactersInString:@"=; \r\n[]()"]];
		
		[components enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
		{
			if (obj && [obj length]>0 && 
				[obj rangeOfCharacterFromSet:nonIP].location==NSNotFound &&
				[obj rangeOfCharacterFromSet:period options:NSBackwardsSearch].location-[obj rangeOfCharacterFromSet:period].location>4 &&
				![alreadySeen objectForKey:obj])
			{
				[alreadySeen setObject:line forKey:obj];			// already seen
				[contextLines setObject:line forKey:obj];			// tag context where address was parsed from
				[addresses addObject:obj];							// address lets us keep ordering same as headers
				[info addObject:[NSString stringWithFormat:@"%@\r\n%@",line,@"[Not yet resolved]"]];
				[lookup resolveAddress:obj delegate:self];
			}
		}];
	}];
}

#pragma mark -
#pragma mark Table View Methods

//--------------------------------------------------------------------------------
// numberOfRowsInTableView
//--------------------------------------------------------------------------------
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [addresses count];
}

//--------------------------------------------------------------------------------
//--------------------------------------------------------------------------------
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn 
			row:(NSInteger)rowIndex
{
	if ([(NSString*)[aTableColumn identifier] compare:@"0"]==NSOrderedSame) {
		return [addresses objectAtIndex:rowIndex];
	}
	return [info objectAtIndex:rowIndex];
}


#pragma mark -
#pragma mark NSDraggingDestination

//--------------------------------------------------------------------------------
// draggingEntered:
//--------------------------------------------------------------------------------
- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender
{
	[self hideDropTarget:NO];
	
	return NSDragOperationCopy;
}

//--------------------------------------------------------------------------------
// draggingExited:
//--------------------------------------------------------------------------------
- (void)draggingExited:(id < NSDraggingInfo >)sender
{
	[self hideDropTarget:YES];
}

//--------------------------------------------------------------------------------
// performDragOperation:
//--------------------------------------------------------------------------------
- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender
{
	[self hideDropTarget:YES];

	// get the pasteboard and copy the data into mail text
	@try {
		NSPasteboard *paste = [sender draggingPasteboard];
		NSData *data = [paste dataForType:NSPasteboardTypeString];
		self.mailText = [[NSString alloc] initWithBytes:[data bytes] length:[data length] 
											   encoding:NSUTF8StringEncoding];
	}
	@catch (NSException * e) {
		NSLog(@"error pasting");
	}
	@finally {
	}
	
	return YES;
}

//--------------------------------------------------------------------------------
// concludeDragOperation:
//--------------------------------------------------------------------------------
- (void)concludeDragOperation:(id < NSDraggingInfo >)sender
{
	[self hideDropTarget:YES];
	[self processMailText];
}


@end








