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
 @header
 
 more later
 
 */

/*!
 @class MBAccountsCoordinator
 
 @abstract more later
 
 @discussion more later
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

/*!
 Designated initialiser.
 */
-(id) initWithMBUser: (MBUser*) aUser;

-(void) refreshAll;
-(void) closeAll;

-(void) clientFinished: (IMAPClient*) client;

-(void) loadFullMessageID: (NSManagedObjectID*) objectID forAccountID: (NSManagedObjectID*) accountID;

-(void) testIMAPClientComm;

@end
