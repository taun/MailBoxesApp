//
//  MBAccountConnectionsCoordintator.h
//  MailBoxes
//
//  Created by Taun Chapman on 04/04/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBAccountsCoordinator.h"
#import "MBox+IMAP.h"
#import "MBMessage+IMAP.h"

#pragma mark - AccountConnectionsCoordintator
@interface MBAccountConnectionsCoordintator : NSObject <IMAPClientDelegate>

@property (nonatomic,strong) MBAccount              *account;
@property (nonatomic,strong) NSMutableSet           *clients;

+(instancetype) newWithAccount: (MBAccount*) account;
/*!
 Designated initializer.
 
 @param account account to coordinate.
 
 @return instancetype
 */
-(instancetype) initWithAccount: (MBAccount*) account;
-(void) updateAccountFolderStructure;
-(void) updateLatestMessagesForMBox: (MBox*) mbox;
-(void) updateLatestMessagesForMBox: (MBox*) mbox olderThan: (NSTimeInterval)time;
-(void) loadFullMessage:(MBMessage*) message;
-(void) closeAll;
-(void) testIMAPClientComm;

#pragma mark - IMAPClientDelegate
-(void) clientFinished:(IMAPClient *)client;

@end
