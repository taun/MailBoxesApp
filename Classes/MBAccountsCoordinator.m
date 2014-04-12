//
//  MBAccountsCoordinator.m
//  MailBoxes
//
//  Created by Taun Chapman on 8/8/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import "MBUser.h"
#import "MBAccount+IMAP.h"

#import "MBTreeNode.h"
#import "MBGroup.h"
#import "MBSidebar.h"

#import "MBAccountsCoordinator.h"
#import "MBAccountConnectionsCoordintator.h"


#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

static const int ddLogLevel = LOG_LEVEL_INFO;

#pragma mark - AccountsCoordintator
@interface MBAccountsCoordinator ()
@property (strong)                      NSMutableDictionary*    accountConnections;

-(void)updateAccountConnections;
-(MBAccountConnectionsCoordintator*) connectionCoordinatorForAccount: (MBAccount*) account;

@end


@implementation MBAccountsCoordinator

@synthesize isFinished = _finished;

static MBAccountsCoordinator *_sharedInstance = nil;
static dispatch_once_t once_token = 0;

+(instancetype) sharedInstanceForUser: (MBUser*) aUser {
    if (aUser && ((_sharedInstance == nil) || ((_sharedInstance != nil) && (_sharedInstance.user != aUser)))) {
        dispatch_once(&once_token, ^{
            _sharedInstance = [[MBAccountsCoordinator alloc] initWithMBUser: aUser];
        });
    }
    return _sharedInstance;
}
+(void)setSharedInstance:(MBAccountsCoordinator *)instance {
    once_token = 0; // resets the once_token so dispatch_once will run again
    _sharedInstance = instance;
}
- (id)initWithMBUser: (MBUser*) aUser {
    self = [super init];
    if (self) {
        // Initialization code here.
        _user = aUser;
        _accountConnections = [[NSMutableDictionary alloc] initWithCapacity:1];
        [self updateAccountConnections];
        [_user addObserver: self forKeyPath: @"accounts" options: NSKeyValueObservingOptionOld context: NULL];
    }
    
    return self;
}
-(void) dealloc {
    [_user removeObserver: self forKeyPath: @"accounts"];
}
-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString: @"accounts"]) {
        // an account was added removed (or edited?)
        [self updateAccountConnections];
    }
}
-(void) updateFolderStructureForAllAccounts {
    for (MBAccount* account in self.user.accounts) {
        [self updateFolderStructureForAccount: account];
    }
}
-(void) updateFolderStructureForAccount: (MBAccount*) account {
    MBAccountConnectionsCoordintator* connCoord = [self connectionCoordinatorForAccount: account];
    
    if (connCoord) {
        [connCoord updateAccountFolderStructure];
    }
}
-(void) updateLatestMessagesForAccount: (MBAccount*) account
                                  mbox: (MBox*) mbox
                             olderThan: (NSTimeInterval)time {
    
    MBAccountConnectionsCoordintator* connCoord = [self connectionCoordinatorForAccount: account];
    
    if (connCoord) {
        [connCoord updateLatestMessagesForMBox: mbox olderThan: time];
    }
}
-(void) loadFullMessage:(MBMessage*) message forAccount:(MBAccount*) account {
    MBAccountConnectionsCoordintator* connCoord = [self connectionCoordinatorForAccount: account];
    
    if (connCoord) {
        [connCoord loadFullMessage: message];
    }
}
-(void) closeAll {
    for (NSString* connCoord in self.accountConnections) {
        [[self.accountConnections objectForKey: connCoord] closeAll];
    }
}

-(void) testIMAPClientCommForAccount: (MBAccount*) account {
    if (account) {
        MBAccountConnectionsCoordintator* connCoord = [self connectionCoordinatorForAccount: account];
        if (connCoord) {
            [connCoord testIMAPClientComm];
        }
    } else {
        for (MBAccount* localAccount in self.user.accounts) {
            MBAccountConnectionsCoordintator* connCoord = [self connectionCoordinatorForAccount: account];
            if (connCoord) {
                [connCoord testIMAPClientComm];
            }
        }
    }
}
/// @name Private methods
#pragma mark - private
-(MBAccountConnectionsCoordintator*) connectionCoordinatorForAccount:(MBAccount *)account {
    MBAccountConnectionsCoordintator* connCoord;
    
    if (account) {
        connCoord = [self.accountConnections objectForKey: account.identifier];
        if (!connCoord) {
            // This should never happen given the observer and updateAccountConnections
            DDLogCWarn(@"An accountConnection was missing for account: %@", account);
            connCoord = [MBAccountConnectionsCoordintator newWithAccount: account];
            [self.accountConnections setObject: connCoord forKey: account.identifier];
        }
    }
    return connCoord;
}
-(void) updateAccountConnections {
    // var access is used here because this gets called in the init
    NSMutableDictionary* deletedConnCoords = [_accountConnections mutableCopy];
    NSMutableDictionary* revisedConnections = [NSMutableDictionary dictionaryWithCapacity: _user.accounts.count];
    
    for (MBAccount* account in _user.accounts) {
        NSString* identifier = account.identifier;
        MBAccountConnectionsCoordintator* connCoord = [_accountConnections objectForKey: identifier];
        
        if (connCoord) {
            // account still exists and there is an existing connectionCoord
            [deletedConnCoords removeObjectForKey: connCoord];
        } else {
            // account exists but there is no connectionCoord
            MBAccountConnectionsCoordintator* newConnCoord = [MBAccountConnectionsCoordintator newWithAccount: account];
            [revisedConnections setObject: newConnCoord forKey: account.identifier];
        }
    }
    // close and remove any account connections not in the new accounts list.
    for (NSString* connCoord in deletedConnCoords) {
        [[deletedConnCoords objectForKey: connCoord] closeAll];
    }
    // clean up
    [_accountConnections removeAllObjects];
    [deletedConnCoords removeAllObjects];
    // save new connections to property
    _accountConnections = revisedConnections;
}
-(MBAccount*) accountForID:(NSManagedObjectID *)accountID {
    MBAccount* account = (MBAccount*)[self.user.managedObjectContext objectWithID: accountID];
    return account;
}

@end
