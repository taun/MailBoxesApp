//
//  MBPortalsCollectionViewController.m
//  MailBoxes
//
//  Created by Taun Chapman on 02/19/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBPortalsCollectionViewController.h"
#import "MBPortalsCollectionView.h"
#import "MBViewPortal.h"
#import "MBViewPortalMBox.h"
#import "MBoxProxy.h"
#import "MBox.h"

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
    [pasteboard setString: @"Testing" forType: MBPasteboardTypeViewPortal];
    
    return YES;
}
/* Sent to the delegate to allow creation of a custom image to represent collection view items during a drag operation. */
//- (NSImage *)collectionView:(NSCollectionView *)collectionView draggingImageForItemsAtIndexes:(NSIndexSet *)indexes withEvent:(NSEvent *)event offset:(NSPointPointer)dragImageOffset {
//    return nil;
//}

/* Invoked to determine a valid drop target. */
- (NSDragOperation)collectionView:(NSCollectionView *)collectionView validateDrop:(id < NSDraggingInfo >)draggingInfo proposedIndex:(NSInteger *)proposedDropIndex dropOperation:(NSCollectionViewDropOperation *)proposedDropOperation {
    return NSDragOperationMove;
}
/* Invoked when the mouse is released over a collection view that previously allowed a drop. */
- (BOOL)collectionView:(NSCollectionView *)collectionView acceptDrop:(id < NSDraggingInfo >)draggingInfo index:(NSInteger)index dropOperation:(NSCollectionViewDropOperation)dropOperation {
    return NO;
}

#pragma mark - MBPortalsCollectionDelegate protocol

-(void) addPortalForMBox: (MBoxProxy*)boxProxy {
    //    self.con
    MBViewPortalMBox* newPortal = [NSEntityDescription insertNewObjectForEntityForName: @"MBViewPortalMBox"
                                                                inManagedObjectContext:self.managedObjectContext];
    
    MBox* mailBox;
    NSPersistentStoreCoordinator* psc = [[self managedObjectContext] persistentStoreCoordinator];
    NSManagedObjectID* objectID = [psc managedObjectIDForURIRepresentation: boxProxy.objectURL];
    if (objectID != nil) {
        NSManagedObject* managedObject = [self.managedObjectContext objectWithID: objectID];
        mailBox = (MBox*)managedObject;
    }
    
    [newPortal setName: [mailBox name]];
    [newPortal setMessageArraySource: mailBox];
    
    [self.currentUser addPortalsObject: newPortal];
}

@end
