//
//  MBAccountWindowController.h
//  MailBoxes
//
//  Created by Taun Chapman on 12/8/10.
//  Copyright 2010 MOEDAE LLC. All rights reserved.
//
// Explain
//

#import <Cocoa/Cocoa.h>
#import "Ping.h"

@class MBAccount;

@interface MBAccountWindowController : NSWindowController <PingDelegate> {
    NSResponder* _savedFirstResponder;
}

@property(weak)            IBOutlet         NSWindow                  *appWindow;
@property(weak)            IBOutlet         NSObjectController        *appSelectedUserObjectController;

@property(weak)            IBOutlet          NSObjectController       *theNewAccountObjectController;
@property(weak)             IBOutlet           NSTextField              *statusField;
@property(weak)             IBOutlet           NSProgressIndicator      *statusLight;
@property(strong)                              Ping                     *pinger;
@property(strong, readonly)                    NSManagedObjectContext   *localManagedContext;
@property(unsafe_unretained,readonly)          NSManagedObjectContext   *appManagedContext;


- (void) editAccountID: (NSManagedObjectID*) account;

- (void)editViewForAccountID: (NSManagedObjectID*) accountID;

- (MBAccount*) currentAccount;

- (IBAction)add:(id)sender;

- (IBAction)complete:sender;
- (IBAction)cancelOperation:sender;

- (IBAction)undo:sender;
- (IBAction)redo:sender;


//- (void)addAccount;

//-(MBAccount*) currentAccount;

- (IBAction)testConnection: (id) sender ;


@end
