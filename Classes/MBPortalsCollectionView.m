//
//  MBCollectionView.m
//  MailBoxes
//
//  Created by Taun Chapman on 05/06/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import "MBPortalsCollectionView.h"
#import "MBPortalViewController.h"
#import "MBoxProxy.h"
#import "MBViewPortalMBox.h"

NSString * const MBPasteboardTypeViewPortal = @"com.moedae.mailboxes.viewportal";

@interface MBPortalsCollectionView ()

@property (nonatomic,assign) BOOL       draggingInView;

@end

@implementation MBPortalsCollectionView

+ (BOOL) requiresConstraintBasedLayout {
    return YES;
}

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

-(NSString*) description {
    return [super description];
}

- (void) awakeFromNib {
    
    [self registerForDraggedTypes:@[@"MBSmartFolder",
                                    @"MBox", @"MBoxProxy", MBPasteboardTypeMbox,
                                    @"MBAccount",
                                    @"MBFavorites",
                                    @"MBAddressList",
                                    MBPasteboardTypeViewPortal, NSStringPboardType]];
    _draggingInView = NO;
}


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


#pragma mark - Drag and Drop
//- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender {
//
//    self.draggingInView = YES;
//    
//    return [(id<MBPortalsCollectionDelegate>)self.delegate draggingEntered: sender];
//}
//- (void)draggingExited:(id < NSDraggingInfo >)sender {
//
//    self.draggingInView = NO;
//    
//    [(id<MBPortalsCollectionDelegate>)self.delegate draggingExited: sender];
//}
//- (void)draggingEnded:(id < NSDraggingInfo >)sender {
//
//    self.draggingInView = NO;
//    
//    [(id<MBPortalsCollectionDelegate>)self.delegate draggingEnded: sender];
//}
- (void)updateDraggingItemsForDrag:(id < NSDraggingInfo >)sender {
    [(id<MBPortalsCollectionDelegate>)self.delegate updateDraggingItemsForDrag: sender];
}

//- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender {
//    return [super draggingUpdated: sender];
////    return [(id<MBPortalsCollectionDelegate>)self.delegate draggingUpdated: sender];
//}

/*
 This method is invoked only if the most recent draggingEntered: or 
 draggingUpdated: message returned an acceptable drag-operation value.
 
 If you want the drag items to animate from their current location on 
 screen to their final location in your view, set the sender object’s 
 animatesToDestination property to YES in your implementation of this method.
 */
//- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender {
//    return [super prepareForDragOperation: sender];
////    return [(id<MBPortalsCollectionDelegate>)self.delegate prepareForDragOperation: sender];
//}

/*
 For this method to be invoked, the previous prepareForDragOperation: message must have returned YES. 
 The destination should implement this method to do the real work of importing the pasteboard data represented by the image.
 
 If the sender object’s animatesToDestination was set to YES in prepareForDragOperation:, 
 then setup any animation to arrange space for the drag items to animate to. Also at this time, 
 enumerate through the dragging items to set their destination frames and destination images.
 */
- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender {
//    return [super performDragOperation: sender];
    return [(id<MBPortalsCollectionDelegate>)self.delegate performDragOperation: sender];
}

/*
 For this method to be invoked, the previous performDragOperation: must have returned YES.
 
 The destination implements this method to perform any tidying up that it needs to do, such 
 as updating its visual representation now that it has incorporated the dragged data. 
 This message is the last message sent from sender to the destination during a dragging session.
 
 If the sender object’s animatesToDestination property was set to YES in prepareForDragOperation:, 
 then the drag image is still visible. At this point you should draw the final visual representation 
 in the view. When this method returns, the drag image is removed form the screen. If your final 
 visual representation matches the visual representation in the drag, this is a seamless transition.
 */
//- (void)concludeDragOperation:(id < NSDraggingInfo >)sender {
//    [super concludeDragOperation: sender];
////    [(id<MBPortalsCollectionDelegate>)self.delegate concludeDragOperation: sender];
//}


@end
