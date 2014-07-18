//
//  MBSidebarView.m
//  MailBoxes
//
//  Created by Taun Chapman on 11/17/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import "MBSidebarView.h"
#import "MBTreeNode+IntersectsSetFix.h"
#import "MBSidebarViewController.h"


static const int ddLogLevel = LOG_LEVEL_WARN;


@implementation MBSidebarView

- (NSDragOperation)draggingSession:(NSDraggingSession *)session 
sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
    switch(context) {
        case NSDraggingContextOutsideApplication:
            return NSDragOperationDelete;
            break;
            
        case NSDraggingContextWithinApplication:
        default:
            return NSDragOperationMove;
            break;
    }
}

- (void)reloadData {
	[super reloadData];
	NSInteger i;
	for( i = 0; i < [self numberOfRows]; i++ ) {
		MBTreeNode* item = [self itemAtRow:i]; // maybe should use NSTreeNode and representedObject
//        MBTreeNode* node = (MBTreeNode*) [item representedObject];
		if( [item isKindOfClass: [MBTreeNode class]] && [item.expandedState boolValue] )
			[self expandItem: item];
	}
}

@end
