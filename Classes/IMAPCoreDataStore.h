//
//  IMAPCoreDataStore.h
//  MailBoxes
//
//  Created by Taun Chapman on 9/28/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMAPClientStore.h"
@class MBAccount;
@class MBox;
@class MBMessage;
@class MailBoxesAppDelegate;
@class MBAddress;

/*!
 Core Data based IMAP client store.
 Part of the triumvirate
 
                IMAPResponseBuffer
 IMAPClient <
                IMAPClientStore
 
 IMAPClient - coordinates IMAPCommands, sync, streaming, ... creates and sets other two
 
    IMAPResponseBuffer - gets response from client and dispatches actions to other two
                         dispatch server actions to client
                         dispatch store actions to store
 
    IMAPClientStore - interfaces response with store
 
 */
@interface IMAPCoreDataStore : NSObject <IMAPClientStore> {
    NSManagedObjectID *_accountID;
    
}

@property (nonatomic, strong, readonly) MailBoxesAppDelegate   *appDelegate;
@property (nonatomic, strong, readonly) NSManagedObjectContext *parentContext;
@property (nonatomic, strong, readonly) NSManagedObjectContext *localManagedContext;
@property (nonatomic, strong, readonly) MBAccount              *account;
@property (nonatomic, strong, readwrite) MBox                  *selectedMBox;

-(id) initWithParentContext: (NSManagedObjectContext*) pcontext AccountID: (NSManagedObjectID *) anAccount; // Designated initializer

-(MBox*) mboxForObjectID: (NSManagedObjectID *) objectID;
-(MBMessage*) messageForObjectID:(NSManagedObjectID *)objectID;

#pragma mark - utilities


@end
