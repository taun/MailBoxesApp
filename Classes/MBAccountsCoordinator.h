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
@class MBox;
@class MBMessage;

@protocol IMAPClientDelegate <NSObject>

-(void) clientFinished:(IMAPClient *)client;

@end

/*!
 The MBAccountsCoordinator manages access to all of a users accounts. There is one MBAccountsCoordintator per user. The application can 
 have more than one user allowing for user switching without having to change to a different OS user. This is useful for iOS apps where 
 there is only one OS user. Spouses can share the App but have individual accounts and settings.
 
 The MBAccountsCoordinator coordinates the IMAP server network connections for the users accounts and portals.
 Each connection is controlled by an IMAPClient. In future there could be other types of server clients coordinated by the MBAccountsCoordinator.
 There can be multiple IMAPClients each with it's own network connection to a server. This is necessary in part, to allow simultaneous access to
 multiple mailboxes in one account. The IMAP protocol only allows for one selected mailbox at a time. Multiple network connections to a server
 allows for multiple selected mailboxes which enables to multi portal functionality of the Mac App.
 
 */
@interface MBAccountsCoordinator : NSObject

/*!
 YES when all account network connections are finished.
 */
@property (nonatomic, assign, readonly) BOOL     isFinished;
@property (strong) MBUser* mainUser;
@property (strong) MBUser* masterUser;
/// @name Public methods

/*!
 Singleton accountCoordinator. Creates a new accountCoordinator if once does not exist.
 If one exists for a different user, the old coordinator is closed and a new one created.
 
 @param mainUser the user
 
 @return an accountCoordinator for the user's accounts.
 */
+(instancetype) sharedInstanceForUser: (MBUser*) mainUser;

/*!
 For test purposes to use a mock accountCoordinator or reseting sharedInstance
 by sending nil.
 
 @param instance mock coordinator or nil to reset. For example, pass nil at end of test method to reset sharedInstance.
 */
+(void)setSharedInstance:(MBAccountsCoordinator *)instance;
/*!
 Designated initialiser.
 
 @param mainUser the user account
 @returns an MBAccountsCoordinator for the user or nil
 */
-(instancetype) initWithMainUser: (MBUser*) mainUser;
-(void) updateFolderStructureForAllAccounts;
-(void) updateFolderStructureForAccount: (MBAccount*) account;
/*!
 Sync messages from account mailbox.
 
 @param account account object
 @param mbox    mbox object
 */
-(void) updateLatestMessagesForAccount: (MBAccount*) account
                                  mbox: (MBox*) mbox;
/*!
 Get messages from account mailbox newer than time.
 
 @param account account object
 @param mbox    mbox object
 @param time    oldest email to fetch as a time interval from now in seconds.
 */
-(void) updateLatestMessagesForAccount: (MBAccount*) account
                                  mbox: (MBox*) mbox
                             olderThan: (NSTimeInterval)time;
/*!
 Close all client connections as soon as possible.
 */
-(void) closeAll;
/*!
 Currently, used to load the full message body and attachments when necessary.
 
 The current functionality is, refreshing an account and all of its messages only fetches and stores the headers.
 The user does not need the body of the message until they wish to see the message by selecting it. 
 
 This creates a new IMAPClient network connection, fetches the full message and saves it which triggers UI
 observers to update the message body display. 
 
 This should not be used for fetching more than one message at a time for the user since it creates a new network connection for each fetch.
 
 Uses GCD to dispatch the network requests on a background queue.
 
 @param message NSManagedObjectID so message object can be retrieved in different thread from the caller.
 @param account NSManagedObjectID so message account can be retrieved in different thread from the caller.
 
 */
-(void) loadFullMessage: (MBMessage*) message forAccount: (MBAccount*) account;

-(void) testIMAPClientCommForAccount: (MBAccount*) account;

@end
