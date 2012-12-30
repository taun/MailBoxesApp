//
//  MBAccountsCoordinator.m
//  MailBoxes
//
//  Created by Taun Chapman on 8/8/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import "MBUser+Accessors.h"
#import "MBAccount+IMAP.h"
#import "IMAPClient.h"

#import "MBTreeNode.h"
#import "MBGroup.h"
#import "MBSidebar.h"

#import "MBAccountsCoordinator.h"

#import "IMAPCoreDataStore.h"

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

static const int ddLogLevel = LOG_LEVEL_INFO;

/*!
 @category MBAccountsCoordinator()
 
 private functions
 
 need to review and at some point move to public
 
 */
@interface MBAccountsCoordinator () 
    @property (nonatomic, assign, readwrite) BOOL                   isFinished;
    @property (strong)                      NSMutableDictionary*    accountConnections;
    @property (nonatomic, readonly)         dispatch_queue_t        accountQueue;

-(void) refreshAllDispatch;
//-(void) refreshAllOperation;

@end


@implementation MBAccountsCoordinator

@synthesize isFinished = _finished;
@synthesize user = _user;
@synthesize accountConnections = _accountConnections;
@synthesize accountQueue = _accountQueue;


- (id)initWithMBUser: (MBUser*) aUser
{
    self = [super init];
    if (self) {
        // Initialization code here.
        _user = aUser;
        _accountConnections = [[NSMutableDictionary alloc] initWithCapacity:1];
    }
    
    return self;
}

-(dispatch_queue_t) accountQueue {
    if (_accountQueue == nil) {
        dispatch_queue_t aQueue = dispatch_queue_create("com.moedae.imapaccount", NULL);
        _accountQueue = aQueue;
    }
    return _accountQueue;
}

/*!
 refreshAll needs to queue up the IMAPClient tasks which don't return until done.
 Concurrently across accounts.
 Callback for when each task is done?
 */
-(void) refreshAll {
    [self refreshAllDispatch];
}

//TODO: need a separate queue for each mail box monitor
// otherwise, the first monitor thread dispatch blocks all future blocks until it is done.
-(void) refreshAllDispatch {
    NSSet* accounts = self.user.accounts;
    for (MBAccount *account in accounts) {
        self.isFinished = NO;
        IMAPClient* client = [[IMAPClient alloc] initWithParentContext: [_user managedObjectContext] AccountID: account.objectID];
        [self.accountConnections setObject: client forKey: account.name];
    }
    
    dispatch_queue_t mQueue = dispatch_get_main_queue();
    for (id key in self.accountConnections) {
        IMAPClient* client = [self.accountConnections objectForKey: key];
        dispatch_async(self.accountQueue, ^{
            [client refreshAll];
            dispatch_async(mQueue, ^{ [self clientFinished: client];}); // could this be sync not async?
        });
    }
    
}

-(void) testIMAPClientComm {
    for (id key in self.accountConnections) {
        IMAPClient* client = [self.accountConnections objectForKey: key];
        NSArray* command = [[NSArray alloc] initWithObjects:@"testMessage:", @"queued command", nil];
        [client.mainCommandQueue addObject: command];
    }
}

//-(void) refreshAllOperation {
//    NSSet *accounts = self.user.childNodes;
//    for (MBAccount *account in accounts) {
//        self.isFinished = NO;
//        IMAPClient* client = [[IMAPClient alloc] initWithAccount: account.objectID];
//        [_accountConnections addObject: client];
//    }
//    if (!_comQueue) {
//        _comQueue = [[NSOperationQueue alloc] init];
//        [_comQueue setName:[NSString stringWithFormat: @"com.moedae.%@", NSStringFromClass([self class])]];
//    }
//    for (IMAPClient* client in _accountConnections) {
//        NSBlockOperation* backgroundTask = [NSBlockOperation blockOperationWithBlock: ^{[client refreshAll];} ];
//        [backgroundTask setCompletionBlock:^{ [self clientFinished: client];}];
//        
//        [_comQueue addOperation: backgroundTask];
//    }
//
//}


-(void) clientFinished:(IMAPClient *)client {
    [self.accountConnections removeObjectForKey: client.clientStore.account.name];
    if ([_accountConnections count] == 0) {
        // no more clients running
        DDLogVerbose(@"%@: All clients closed.", NSStringFromClass([self class]));
        self.isFinished = YES;
    }
}

-(void) closeAll {
    for (id key in self.accountConnections) {
        IMAPClient *client = [self.accountConnections objectForKey: key];
        client.isCancelled = YES;
    }    
}

-(void) loadFullMessageID:(NSManagedObjectID*) messageID forAccountID:(NSManagedObjectID*) accountID {
    IMAPClient* client = [[IMAPClient alloc] initWithParentContext: [_user managedObjectContext] AccountID: accountID];
    dispatch_async(self.accountQueue, ^{
        [client loadFullMessageID: messageID];
    });
}
    
@end
