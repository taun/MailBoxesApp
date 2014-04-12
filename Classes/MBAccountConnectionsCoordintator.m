//
//  MBAccountConnectionsCoordintator.m
//  MailBoxes
//
//  Created by Taun Chapman on 04/04/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBAccountConnectionsCoordintator.h"
#import "MBAccount+IMAP.h"
#import "MBMessage+IMAP.h"
#import "IMAPClient.h"
//#import "IMAPCoreDataStore.h"

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

static const int ddLogLevel = LOG_LEVEL_INFO;

@interface MBAccountConnectionsCoordintator ()
/*!
 Client used for top level account maintenance. Not tied to any selected mail box.
 */
@property (nonatomic,strong) IMAPClient     *rootClient;
/*!
 Return an IMAPClient with the desired mbox selected. If a client already exist for the selected mbox,
 that client is returned. If no connection exists for the desired selection and the connectionLimit is
 not yet reached, create a new IMAPClient connection for the account and select the desired mbox.
 If no connection exists for the desired selection and the connectionLimit is reached, queue up the new
 selection on the connection with the longest idle time.
 
 @param mbox mbox to be selected if not already selected.
 
 @return IMAPClient to use for the selected mbox.
 */
-(IMAPClient*) clientForSelectedBox: (MBox*) mbox;
-(IMAPClient*) longestIdleClient;
@end

@implementation MBAccountConnectionsCoordintator

+(instancetype) newWithAccount:(MBAccount *)account {
    return [[[self class] alloc] initWithAccount: account];
}
- (instancetype)initWithAccount:(MBAccount *)account {
    self = [super init];
    if (self) {
        _account = account;
        
        NSUInteger limit = ([account.connectionLimit unsignedIntegerValue] - 1);
        _clients = [NSMutableSet setWithCapacity: limit];
    }
    return self;
}
-(void) dealloc {
    [self closeAll];
}
-(IMAPClient*) rootClient {
    if (!_rootClient) {
        _rootClient = [[IMAPClient alloc] initWithParentContext: self.account.managedObjectContext AccountID: self.account.objectID];
        _rootClient.delegate = self;
    }
    return _rootClient;
}
-(void) updateAccountFolderStructure {
    [self.rootClient updateAccountFolderStructure];
}
-(void) updateLatestMessagesForMBox: (MBox*) mbox
                          olderThan: (NSTimeInterval)time {
    if (mbox) {
        IMAPClient* client = [self clientForSelectedBox: mbox];
        if (client) {
            [client updateLatestMessagesForMBox: mbox olderThan: time];
        }
    }
}
-(void) loadFullMessage:(MBMessage*) message {

    if (message.mbox) {
        IMAPClient* client = [self clientForSelectedBox: message.mbox];
        if (client) {
            [client loadFullMessage: message];
        }
    }
}

-(void) closeAll {
    for (IMAPClient *client in self.clients) {
        client.isCancelled = YES;
    }
    [self.clients removeAllObjects];
    self.rootClient.isCancelled = YES;
    self.rootClient = nil;
}
-(void) testIMAPClientComm {
    [self.rootClient testMessage: @"queued command"];
}
/// @name IMAPClientDelegate
#pragma mark - IMAPClientDelegate
-(void) clientFinished:(IMAPClient *)client {
    [self.clients removeObject: client];
    if ([_clients count] == 0) {
        // no more clients running
        DDLogVerbose(@"%@: All clients closed.", NSStringFromClass([self class]));
    }
}
/// @name Private methods
#pragma mark - private
-(IMAPClient*) longestIdleClient {
    IMAPClient* longestIdled;
    NSTimeInterval longestInterval = [NSDate timeIntervalSinceReferenceDate];
    
    for (IMAPClient* client in self.clients) {
        // want idle furthest in the past which is the smallest NSTimeInterval
        NSTimeInterval idleTime;
        idleTime = client.idleSince;
        if (idleTime <= longestInterval) {
            longestIdled = client;
            longestInterval = idleTime;
        }
    }
    return longestIdled;
}
-(IMAPClient*) clientForSelectedBox:(MBox *)mbox {
    IMAPClient* selectedClient;
    
    NSString* desiredPath = mbox.fullPath;
    
    for (IMAPClient* client in self.clients) {
        NSString* clientPath = client.selectedMBoxPath;
        if ([clientPath isEqualToString: desiredPath]) {
            selectedClient = client;
        }
    }
    
    if (!selectedClient) {
        // none found need to create one
        if (self.clients.count < ([self.account.connectionLimit unsignedIntegerValue] - 1)) {
            selectedClient = [[IMAPClient alloc] initWithParentContext: self.account.managedObjectContext AccountID: self.account.objectID];
            selectedClient.delegate = self;
            [self.clients addObject: selectedClient];
        } else {
            // limit reached so get the longest idled client
            selectedClient = [self longestIdleClient];
        }
    }
    
    return selectedClient;
}
-(MBox*) mboxForID:(NSManagedObjectID *)mboxID {
    MBox* mbox = (MBox*)[self.account.managedObjectContext objectWithID: mboxID];
    return mbox;
}

@end

