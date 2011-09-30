//
//  ProvenanceAppDelegate.h
//  Provenance
//
//  Created by Jonathan Watmough on 8/25/11.
//	Do whatever you want with this code.


#import <Cocoa/Cocoa.h>

@class comDotMelissaData;

@interface ProvenanceAppDelegate : NSObject <NSApplicationDelegate,
											 NSWindowDelegate,
											 JWDomainInfoDelegate,
											 NSTableViewDataSource>
{
	comDotMelissaData *lookup;

	NSString		*mailText;
	NSMutableArray	*addresses;
	NSMutableArray	*info;
	
	NSMutableDictionary	*contextLines;

    NSWindow	*window;
	NSTableView	*tableView;
	NSImageView	*dropTarget;
}

@property (retain) IBOutlet NSString		*mailText;
@property (retain) IBOutlet NSMutableArray	*addresses;
@property (retain) IBOutlet NSMutableArray	*info;

// map found addresses to mail header lines for context
@property (retain) IBOutlet NSMutableDictionary	*contextLines;



@property (assign) IBOutlet NSWindow	*window;
@property (assign) IBOutlet NSTableView	*tableView;
@property (retain) IBOutlet	NSImageView	*dropTarget;

// NSDraggingDesination Informal Protocol
- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender;
- (void)draggingExited:(id < NSDraggingInfo >)sender;
- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender;
- (void)concludeDragOperation:(id < NSDraggingInfo >)sender;

@end
