//
//  MBPPEWindowController.h
//  MailBoxes
//
//  Created by Taun Chapman on 3/3/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*
 Smart Folder/Portal Predicate Editor Controller
 */

@interface MBPPEWindowController : NSWindowController <NSMetadataQueryDelegate> {
@public    
    NSInteger               _previousRowCount;       // keep track of # rows in 'predicateEditor'

}
 
@property(strong)           IBOutlet      NSWindow                    *appWindow;

@property(strong)                       NSMetadataQuery             *query;
@property(weak)           IBOutlet      NSPredicateEditor           *predicateEditor;
@property(assign)                       NSInteger                    previousRowCount;


@property(weak)           IBOutlet      NSArrayController           *portalArrayController;
@property(strong)         IBOutlet      NSObjectController          *theNewPortalObjectController;
@property(weak)           IBOutlet      NSObjectController          *appSelectedUserObjectController;
//@property(weak)           IBOutlet      NSCompoundPredicate         *predicate;

@property(strong,readonly)               NSManagedObjectContext      *localManagedContext;
@property(weak, readonly)                NSManagedObjectContext      *appManagedContext;


// Designated initializer
- (id)initWithNib: (NSString *) theNib ;

- (IBAction)predicateEditorChanged:(id)sender;

- (IBAction)add:(id)sender;

- (IBAction)complete:sender;
- (IBAction)cancelOperation:sender;

- (IBAction)undo:sender;
- (IBAction)redo:sender;


@end
