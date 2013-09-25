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
 The MBAccountsCoordinator manages access to all of a users accounts. There is one MBAccountsCoordintator per user. The application can 
 have more than one user allowing for user switching without having to change to a different OS user. This is useful for iOS apps where 
 there is only one OS user. Spouses can share the App but have individual accounts and settings.
 
 The MBAccountsCoordinator coordinates the IMAP server network connections for the users accounts and portals.
 Each connection is controlled by an IMAPClient. In future there could be other types of server clients coordinated by the MBAccountsCoordinator.
 There can be multiple IMAPClients each with it's own network connection to a server. This is necessary in part, to allow simoultaneous access to 
 multiple mailboxes in one account. The IMAP protocol only allows for one selected mailbox at a time. Multiple network connections to a server
 allows for multiple selected mailboxes which enables to multi portal functionality of the Mac App.
 
 */
@interface MBAccountsCoordinator : NSObject {
    MBUser*         _user;
    BOOL            _finished;
@private
    NSMutableDictionary*   _accountConnections;
    //NSOperationQueue*       _comQueue;
}

/*!
 YES when all account network connections are finished.
 */
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
 Fetches all of the mailboxes and message headers for all of the accounts defined for the MBAccountsCoordinator user.
 
 All IMAP network activity is performed by IMAPClients on a background queue.
 
 Currently, IMAPClient is hardwired to only fetch X number of headers for each mailbox. This number is set in 
 property IMAPClient.syncQuantaLW and is meant to be a user preference.
 
 Old notes -refreshAll needs to queue up the IMAPClient tasks which don't return until done.
            Concurrently across accounts.
            Callback for when each task is done? Should be clientFinished:
 
 @see clientFinished:
 */
-(void) refreshAll;
/*!
 Close all client connections as soon as possible.
 */
-(void) closeAll;

/*!
 A callback method to remove the client from the list of active clients and close it.
 
 @param client the client which has finished it's work.
 */
-(void) clientFinished: (IMAPClient*) client;

#pragma message "This should use the existing client connection."
/*!
 Currently, used to load the full message body and attachments when necessary.
 
 The current functionality is, refreshing an account and all of its messages only fetches and stores the headers.
 The user does not need the body of the message until they wish to see the message by selecting it. 
 
 This creates a new IMAPClient network connection, fetches the full message and saves it which triggers UI
 observers to update the message body display. 
 
 This should not be used for fetching more than one message at a time for the user since it creates a new network connection for each fetch.
 
 Uses GCD to dispatch the network requests on a background queue.
 
 @param objectID message NSManagedObjectID so message object can be retrieved in different thread from the caller.
 @param accountID account NSManagedObjectID so message account can be retrieved in different thread from the caller.
 
 */
-(void) loadFullMessageID: (NSManagedObjectID*) objectID forAccountID: (NSManagedObjectID*) accountID;

-(void) testIMAPClientComm;

@end
