//
//  MBCollectionView.m
//  MailBoxes
//
//  Created by Taun Chapman on 05/06/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import "MBPortalsCollectionView.h"
#import "MBPortalViewController.h"

@implementation MBPortalsCollectionView


/*!
    @method newItemForRepresentedObject:
 
    @discussion
    Not really needed at the moment.
    @param object more later
 
    @result the item for represented object
 
 */
//- (NSCollectionViewItem *)newItemForRepresentedObject:(id)object {
//    
//    NSCollectionViewItem *newItem = [super newItemForRepresentedObject: object];
//    
//    
//    return newItem;
//}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString: @"selectedMessages"]) {
        // new selection set
        NSSortDescriptor* sortDesc = [NSSortDescriptor sortDescriptorWithKey: @"dateSent" ascending: NO];
        NSArray* descriptors = @[sortDesc];
        NSArray* objects = [((MBPortalViewController*)object).selectedMessages sortedArrayUsingDescriptors: descriptors];
        
        [self.viewedMessagesArrayController setContent: objects];
        BOOL selectionChanged = [self.viewedMessagesArrayController setSelectedObjects: objects];
        
        // Set the selected portal to the current.
        // Need to add code to handle selection sets across portals?
        if (selectionChanged) {
            [self setSelectionIndexes: [NSIndexSet indexSetWithIndex: [[self subviews] indexOfObject: [object view]]]];
        }

    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
@end
