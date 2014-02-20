//
//  MBCollectionView.h
//  MailBoxes
//
//  Created by Taun Chapman on 05/06/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@class MBoxProxy;

extern NSString * const MBPasteboardTypeViewPortal;

@protocol MBPortalsCollectionDelegate <NSObject>

-(void) addPortalForMBox: (MBoxProxy*)boxProxy atIndex: (NSUInteger) index;
-(void) deletePortalForDragSession: (NSDraggingSession*) session;

- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender;
- (void)draggingExited:(id < NSDraggingInfo >)sender;
- (void)draggingEnded:(id < NSDraggingInfo >)sender;
- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender;
- (void)updateDraggingItemsForDrag:(id < NSDraggingInfo >)sender;
//- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender;
- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender;
- (void)concludeDragOperation:(id < NSDraggingInfo >)sender;
@end

/*!
 @header
 
 Collect the various portal message selections.
 
 Note, normally the collectionView selection refers to the item in the collection which in this
 case is a portal.
 
 We also need to track the currently selected messages in the portals.
 
 For now, we will only allow one message selection at a time. The portal needs to notify the collection view
 delegate of any new selections, set all the other portal selections to none. Also need to be able to handle
 multiple selections.
 
 Need delegate methods for 
    selection did change
 
    Subclass in order to add observer of currently selected message
    as each new portal is added.
 */
@interface MBPortalsCollectionView : NSCollectionView 

@property (weak)            IBOutlet NSArrayController          *viewedMessagesArrayController;


@end
