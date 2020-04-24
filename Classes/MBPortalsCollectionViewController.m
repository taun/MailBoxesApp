//
//  MBPortalsCollectionViewController.m
//  MailBoxes
//
//  Created by Taun Chapman on 02/19/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBPortalsCollectionViewController.h"
#import "MBPortalsCollectionView.h"

#import "MBViewPortal+Extra.h"
#import "MBViewPortalMBox+Extra.h"
#import "MBViewPortalSelection+Extra.h"
#import "MBViewPortalSmartFolder+Extra.h"

#import "NSManagedObject+Shortcuts.h"

#import <MoedaeMailPlugins/MBoxProxy.h>
#import "MBox.h"

@interface MBPortalsCollectionViewController ()

//@property (nonatomic,assign) NSInteger  dragInsertion;

@end

@implementation MBPortalsCollectionViewController

- (void) awakeFromNib {

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(managedObjectContextDidChange:)
                                                 name:NSManagedObjectContextObjectsDidChangeNotification
                                               object: self.managedObjectContext];
}

-(NSManagedObjectContext*) managedObjectContext {
    return [self.currentUser managedObjectContext];
}

-(MBUser*) currentUser {
    return (MBUser*)[self.userController content];
}

- (void) managedObjectContextDidChange: (NSNotification *)notification {

}

#pragma mark - Portals NSCollectionViewDelegate Protocol
/*
 Only for drag and drop within the CollectionView.
 The CollectionView handles objects dropped from other views onto collectionView.
 Perhaps should be moved to the CollectionViewController class ?
 */
/* Returns whether the collection view can attempt to initiate a drag for the given event and items. */
- (BOOL)collectionView:(NSCollectionView *)collectionView canDragItemsAtIndexes:(NSIndexSet *)indexes withEvent:(NSEvent *)event {
    BOOL canDrag = NO;
    if (collectionView.content.count > 1) {
        canDrag = YES;
    }
    return canDrag;
}
/* Invoked after it has been determined that a drag should begin, but before the drag has been started. */
- (BOOL)collectionView:(NSCollectionView *)collectionView writeItemsAtIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard {
    
    [pasteboard declareTypes: @[MBPasteboardTypeViewPortal,NSStringPboardType] owner: self];
    [pasteboard setString: [NSString stringWithFormat:@"%lu", (unsigned long)[indexes firstIndex]] forType: MBPasteboardTypeViewPortal];
    
    return YES;
}
/* Sent to the delegate to allow creation of a custom image to represent collection view items during a drag operation. */
//- (NSImage *)collectionView:(NSCollectionView *)collectionView draggingImageForItemsAtIndexes:(NSIndexSet *)indexes withEvent:(NSEvent *)event offset:(NSPointPointer)dragImageOffset {
//    return nil;
//}

/* Invoked to determine a valid drop target. */
- (NSDragOperation)collectionView:(NSCollectionView *)collectionView validateDrop:(id < NSDraggingInfo >)draggingInfo proposedIndex:(NSInteger *)proposedDropIndex dropOperation:(NSCollectionViewDropOperation *)proposedDropOperation {
    NSDragOperation dragOperation = NSDragOperationNone;
    
    if ([[draggingInfo draggingPasteboard] canReadItemWithDataConformingToTypes: @[MBPasteboardTypeViewPortal]]) {
        // intra collectionView dragging
        // Assume only one portal can be selected for drag and drop so selection always has one index
        BOOL samePortal = [[collectionView selectionIndexes] containsIndex: *proposedDropIndex];
        BOOL rightPortal = [[collectionView selectionIndexes] containsIndex: *proposedDropIndex - 1];
        
        if ((*proposedDropIndex != -1) && !samePortal && !rightPortal) {
            if ((proposedDropOperation != nil) && (*proposedDropOperation == NSCollectionViewDropOn)) {
                *proposedDropOperation = NSCollectionViewDropBefore;
            }
            dragOperation = NSDragOperationMove;
            //        self.dragInsertion = *proposedDropIndex; // should set in acceptDrop: below?
        }
        
    } else if ([[draggingInfo draggingPasteboard] canReadItemWithDataConformingToTypes: @[MBPasteboardTypeMbox]]) {
        // Dragging from the sidebar
        // no NSDragOperationOn only Move
        dragOperation = NSDragOperationMove;
    }

    
    return dragOperation;
}
/* Invoked when the mouse is released over a collection view that previously allowed a drop. */
- (BOOL)collectionView:(NSCollectionView *)collectionView acceptDrop:(id < NSDraggingInfo >)draggingInfo index:(NSInteger)index dropOperation:(NSCollectionViewDropOperation)dropOperation {

    if ([[draggingInfo draggingPasteboard] canReadItemWithDataConformingToTypes: @[MBPasteboardTypeViewPortal]]) {
        // Assume only one portal can be selected for drag and drop so selection always has one index
        //        NSString* draggedPortal = [[sender draggingPasteboard] stringForType: MBPasteboardTypeViewPortal];
        NSUInteger selectedPortal = [collectionView.selectionIndexes firstIndex];
//        NSUInteger newPosition = self.dragInsertion;
        
        
        MBViewPortal* draggedPortal = [collectionView.content objectAtIndex: selectedPortal];
        
        [self movePortal: draggedPortal toIndex: index];
        
    } else if ([[draggingInfo draggingPasteboard] canReadItemWithDataConformingToTypes: @[MBPasteboardTypeMbox]]) {
        //
        NSArray* classes = @[[MBoxProxy class], [NSString class]];
        NSArray* objects = [[draggingInfo draggingPasteboard] readObjectsForClasses: classes options: nil];
        id draggedItem = [objects firstObject];
        if ([draggedItem isKindOfClass:[MBoxProxy class]]) {
            [self addPortalForMBox: draggedItem atIndex: index];
        }
    }
    
    // create new portal!
    return YES;
}

#pragma mark - MBPortalsCollectionDelegate protocol

-(void) removePortal: (MBViewPortal*) portal {
    NSMutableOrderedSet* portals = [self.currentUser.portals mutableCopy];
    
   [portals removeObject: portal];
    
    self.currentUser.portals = [portals copy];
    
    portal.user = nil;
    
    [self.currentUser.managedObjectContext deleteObject: portal];
}

-(void) movePortal: (MBViewPortal*) portal toIndex: (NSUInteger) newIndex {
    NSMutableOrderedSet* portals = [self.currentUser.portals mutableCopy];
    
    NSUInteger selectedPortalIndex = [portals indexOfObject: portal];
    
    if (selectedPortalIndex != NSNotFound) {
        // portal is already in array
        [portals removeObject: portal];
        
        if (newIndex > selectedPortalIndex) {
            // moving to the right
            // need to account for removing from current position and adding to new after everything slid left
            newIndex = newIndex - 1;
        }
    }
    
    [portals insertObject: portal atIndex: newIndex];
    
    self.currentUser.portals = [portals copy];
}

-(void) addPortalForMBox: (MBoxProxy*)boxProxy atIndex: (NSUInteger) index {
    //    self.con
    MBViewPortalMBox* newPortal = [MBViewPortalMBox insertNewObjectIntoContext: self.managedObjectContext];
    
    MBox* mailBox;
    NSPersistentStoreCoordinator* psc = [[self managedObjectContext] persistentStoreCoordinator];
    NSManagedObjectID* objectID = [psc managedObjectIDForURIRepresentation: boxProxy.objectURL];
    if (objectID != nil) {
        NSManagedObject* managedObject = [self.managedObjectContext objectWithID: objectID];
        mailBox = (MBox*)managedObject;
    }
    
    [newPortal setMessageArraySource: mailBox];
    
    [self movePortal: newPortal toIndex: index];
//    newPortal.user = self.currentUser;
//    [self.currentUser addPortalsObject: newPortal];
}

-(void) deletePortalForDragSession: (NSDraggingSession*) session {
    if ([[session draggingPasteboard] canReadItemWithDataConformingToTypes: @[MBPasteboardTypeViewPortal]]) {
        NSString* draggedPortalIndex = [[session draggingPasteboard] stringForType: MBPasteboardTypeViewPortal];
        NSUInteger index = [draggedPortalIndex integerValue]; // returns 0 for a bad string. How to detect bad?
        MBViewPortal* portalToDelete = [self.currentUser.portals objectAtIndex: index];
        [self removePortal: portalToDelete];
    }
}

#pragma mark - Forwarded View Drag and Drop
- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender {
    
    NSDragOperation dragOperation = NSDragOperationNone;
    
    if ([[sender draggingPasteboard] canReadItemWithDataConformingToTypes: @[MBPasteboardTypeViewPortal]]) {
        //
        dragOperation = NSDragOperationMove;
    } else if ([[sender draggingPasteboard] canReadItemWithDataConformingToTypes: @[MBPasteboardTypeMbox]]) {
        //
        dragOperation = NSDragOperationLink;
    }
    return dragOperation;
}

- (void)draggingExited:(id < NSDraggingInfo >)sender {
    
}
- (void)draggingEnded:(id < NSDraggingInfo >)sender {
    
}
- (void)updateDraggingItemsForDrag:(id < NSDraggingInfo >)sender {
    
    if ([[sender draggingPasteboard] canReadItemWithDataConformingToTypes: @[MBPasteboardTypeMbox]]) {
        //
        [sender enumerateDraggingItemsWithOptions:NSDraggingItemEnumerationClearNonenumeratedImages forView:self.view classes:[NSArray arrayWithObject:[MBoxProxy class]] searchOptions: @{} usingBlock:^(NSDraggingItem *draggingItem, NSInteger idx, BOOL *stop) {
//            draggingItem.draggingFrame = pcvController.view.frame;
            draggingItem.imageComponentsProvider = ^ {
                /* Loading the image file and rendering it to create the drag image components can be slow, particularly for files on a newtork volumne, or large images or for a large number of files in the drop. One technique for dealing with this is to start caching the images in a background thread during -draggingEntered: for use here. If your background thread does not complete before this method is called, you can flag that you need to updat the images and update them during -draggingUpdate: if that flag is set.
                 */
                NSDraggingImageComponent *imageComponent;
                
                
                // dragging Image Components are painted from back to front, so but the background image first in the array.
                NSImage* dragImage = [NSImage imageNamed: @"PortalDragOutline"];
                NSSize imageSize = dragImage.size;
                NSRect imageRect = NSMakeRect(0, 0, imageSize.width, imageSize.height);
                
                imageComponent = [NSDraggingImageComponent draggingImageComponentWithKey:@"Portal"];
                imageComponent.frame = imageRect;
                imageComponent.contents = dragImage;

                return @[imageComponent];
            };
        }];

        sender.numberOfValidItemsForDrop = 1;
    }

}

//- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender {
//    
//    NSDragOperation dragOperation = NSDragOperationNone;
//    
//    if ([[sender draggingPasteboard] canReadItemWithDataConformingToTypes: @[MBPasteboardTypeViewPortal]]) {
//        //
//        dragOperation = NSDragOperationMove;
//    } else if ([[sender draggingPasteboard] canReadItemWithDataConformingToTypes: @[MBPasteboardTypeMbox]]) {
//        //
//        dragOperation = NSDragOperationLink;
//    }
//    return dragOperation;
//}

/*
 This method is invoked only if the most recent draggingEntered: or
 draggingUpdated: message returned an acceptable drag-operation value.
 
 If you want the drag items to animate from their current location on
 screen to their final location in your view, set the sender object’s
 animatesToDestination property to YES in your implementation of this method.
 */
- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender {
    
    [sender setAnimatesToDestination: YES];
    return YES;
}

- (void)concludeDragOperation:(id<NSDraggingInfo>)sender { 
    // TODO: implement
}


- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender { 
    // TODO: implement

    return NO;
}


/*
 For this method to be invoked, the previous prepareForDragOperation: message must have returned YES.
 The destination should implement this method to do the real work of importing the pasteboard data represented by the image.
 
 If the sender object’s animatesToDestination was set to YES in prepareForDragOperation:,
 then setup any animation to arrange space for the drag items to animate to. Also at this time,
 enumerate through the dragging items to set their destination frames and destination images.
 
 The standard NSCollectionView does not seem able to handle to reordering after a drag and drop so we do it here.
 */
//- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender {
//    
//    if ([[sender draggingPasteboard] canReadItemWithDataConformingToTypes: @[MBPasteboardTypeViewPortal]]) {
//        // Assume only one portal can be selected for drag and drop so selection always has one index
////        NSString* draggedPortal = [[sender draggingPasteboard] stringForType: MBPasteboardTypeViewPortal];
//        NSUInteger selectedPortal = [self.view.selectionIndexes firstIndex];
//        NSUInteger newPosition = self.dragInsertion;
//        
//        MBViewPortal* draggedPortal = [self.view.content objectAtIndex: selectedPortal];
//        
//        NSMutableOrderedSet* portals = [self.currentUser.portals mutableCopy];
//        
//        [portals removeObject: draggedPortal];
//        
//        if (newPosition>selectedPortal) {
//            // moving to the right
//            // need to account for removing from current position and adding to new after everything slid left
//            newPosition = newPosition -1;
//        }
//        
//        [portals insertObject: draggedPortal atIndex: newPosition];
//        
//        self.currentUser.portals = [portals copy];
////        sender drag
//        
//    } else if ([[sender draggingPasteboard] canReadItemWithDataConformingToTypes: @[MBPasteboardTypeMbox]]) {
//        //
//        NSArray* classes = @[[MBoxProxy class], [NSString class]];
//        NSArray* objects = [[sender draggingPasteboard] readObjectsForClasses: classes options: nil];
//        id draggedItem = [objects firstObject];
//        if ([draggedItem isKindOfClass:[MBoxProxy class]]) {
//            [self addPortalForMBox: draggedItem];
//        }
//    }
//    
//    // create new portal!
//    return YES;
//}

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
//    NSString* draggedPortal = [[sender draggingPasteboard] stringForType: MBPasteboardTypeViewPortal];
//}

@end
