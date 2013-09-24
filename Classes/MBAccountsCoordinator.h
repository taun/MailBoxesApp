//
//  MBAccountsCoordinator.h
//  MailBoxes
//
//  Created by Taun Chapman on 8/8/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MBUser;
@class IMAPClient;
@class MBAccount;

/*!
 more later
 */
@interface MBAccountsCoordinator : NSObject {
    MBUser*         _user;
    BOOL            _finished;
@private
    NSMutableDictionary*   _accountConnections;
    //NSOperationQueue*       _comQueue;
}

@property (nonatomic, assign, readonly) BOOL     isFinished;
@property (strong) MBUser* user;
/// @name Public methods
/*!
 Designated initialiser.
 
 @param aUser the user account
 @returns an MBAccountsCoordinator for the user or nil
 */
-(id) initWithMBUser: (MBUser*) aUser;

/*!
 refreshAll needs to queue up the IMAPClient tasks which don't return until done.
 Concurrently across accounts.
 Callback for when each task is done?
 */
-(void) refreshAll;
/*!
 Close all client connections as soon as possible.
 */
-(void) closeAll;

/*!
 Close the IMAPClient connection when finished with the client.
 */
-(void) clientFinished: (IMAPClient*) client;

/*!
 This should use the existing client connection.
 */
-(void) loadFullMessageID: (NSManagedObjectID*) objectID forAccountID: (NSManagedObjectID*) accountID;

-(void) testIMAPClientComm;

@end
