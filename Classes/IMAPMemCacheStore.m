//
//  IMAPMemCacheStore.m
//  MailBoxes
//
//  Created by Taun Chapman on 9/28/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import "IMAPMemCacheStore.h"

#import "MBAccount+IMAP.h"
#import "MBox+IMAP.h"
#import "MBMessage+IMAP.h"
#import "MBAddress+IMAP.h"
#import "MBMime+IMAP.h"
#import "MBMimeData+IMAP.h"

#import "NSManagedObject+Shortcuts.h"

#import "MBRFC2822.h"

#import <MoedaeMailPlugins/NSString+IMAPConversions.h>
#import <MoedaeMailPlugins/NSObject+TokenDispatch.h>

static const int ddLogLevel = LOG_LEVEL_INFO;

@interface IMAPMemCacheStore ()

@property (nonatomic, strong, readwrite) NSManagedObjectContext *parentContext;
@property (nonatomic, strong, readwrite) NSManagedObjectContext *localManagedContext;
@property (nonatomic, strong, readwrite) MBAccount              *account;

@property (nonatomic,strong) NSMutableSet                       *serverUids;

@end

@implementation IMAPMemCacheStore

@synthesize selectedMBox = _selectedMBox;

-(id) init {
    // Initialization code here.
    return [self initWithParentContext: nil AccountID: nil];
}

-(id) initWithParentContext: (NSManagedObjectContext*) pcontext AccountID: (NSManagedObjectID *) anAccount {
    assert(anAccount != nil);
    
    self = [super init];
    if (self) {
        _parentContext = pcontext;
        _accountID = anAccount;
        // We do not assign a local context yet because it may still be on the main thread
        _localManagedContext = nil;
        _selectedMBox = nil;
        _account = nil;
    }
    return self;
}

#pragma mark - Core Data 
-(NSManagedObjectContext *) localManagedContext {
    if (_localManagedContext==nil) {
        _localManagedContext = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSPrivateQueueConcurrencyType];
        [self.localManagedContext setParentContext: _parentContext];
        [self.localManagedContext setUndoManager:nil];
        [self.localManagedContext setMergePolicy: NSOverwriteMergePolicy];
//        [[NSNotificationCenter defaultCenter] addObserver:self
//               selector:@selector(mergeChanges:) 
//                   name:NSManagedObjectContextDidSaveNotification
//                 object:self.localManagedContext];

    }
    return _localManagedContext;
}

-(MBAccount *) account {
    if (_account==nil) {
        
        [self.localManagedContext performBlockAndWait:^{
            _account = (MBAccount *)[_localManagedContext objectWithID: _accountID];
        }];

    }
    return _account;
}
-(MBox *) selectedMBox {
    if (_selectedMBox==nil) {
        
        [self.localManagedContext performBlockAndWait:^{
            _selectedMBox = (MBox *)[_localManagedContext objectWithID: _mboxID];
        }];
        
    }
    return _selectedMBox;
}
-(void) setSelectedMBox:(MBox *)selectedMBox {
    if (_selectedMBox != selectedMBox) {
        _selectedMBox = selectedMBox;
        _mboxID = [selectedMBox objectID];
    }
}

- (void) save {
    

}

//-(void) mergeChanges:(NSNotification *)notification {
//	// Merge changes into the main context on the main thread
//	[self.appManagedContext performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:)
//                                  withObject:notification
//                               waitUntilDone:YES];	
//}
-(MBox*) mboxForObjectID: (NSManagedObjectID *) objectID {
    __block MBox* foundObject;
    
    [self.localManagedContext performBlockAndWait:^{
        foundObject = (MBox*)[_localManagedContext objectWithID: objectID];
    }];
    
    return foundObject;
}
-(MBMessage*) messageForObjectID:(NSManagedObjectID *)objectID {
    __block MBMessage* foundObject;
    
    [self.localManagedContext performBlockAndWait:^{
        foundObject = (MBMessage*)[_localManagedContext objectWithID: objectID];
    }];

    return foundObject;
}

#pragma mark - MailBox

-(MBox *) selectMailBox: (NSString *) fullPath {
    self.serverUids = [NSMutableSet new];
    return nil;
}


/*
Example

 * XLIST (\HasNoChildren) "/" "GBSchool"
 * XLIST (\HasChildren \Inbox) "/" "INBOX"
 * XLIST (\NoInferiors \Spam) "/" "Junk"

 */
-(BOOL) setMailBoxFlags:(NSArray *)flagTokens onPath:(NSString *)fullPath withSeparator:(NSString *)aSeparator {
    __block MBox *mbox = nil;
    
    if (![flagTokens containsObject: @"\\NoSelect"]) {
        // Either returns the existing folder or creates a new one.
        // Almost all except the first time, this should be an existing box.
        [self.localManagedContext performBlockAndWait:^{
            mbox = [self.account getMBoxAtPath: fullPath withSeparator: aSeparator createIntermediateMBoxes: YES];
        }];

    }
    if (mbox) {
        
        for (NSString* flag in flagTokens) {
            //
            [self performCleanedSelectorString: flag prefixedBy: @"setMBoxFlag" fallbackSelector: @"setMBoxFlagUnknown:" withObject: mbox];
        }
    }
    return YES;
}
-(void) setMBoxFlagUnknown: (MBox*)mbox {
    DDLogCInfo(@"Unknown mailbox flag for: %@", mbox);
}
-(void) setMBoxFlagNoinferiors: (MBox*)mbox {
    mbox.noInferiors = @YES;
}
-(void) setMBoxFlagMarked: (MBox*)mbox {
    mbox.isMarked = @YES;
}
-(void) setMBoxFlagUnmarked: (MBox*)mbox {
    mbox.isMarked = @NO;
}
-(void) setMBoxFlagNoselect: (MBox*)mbox {
    mbox.noInferiors = @YES;
}
-(void) setMBoxFlagHaschildren: (MBox*)mbox {
    mbox.isLeaf = @NO;
}
-(void) setMBoxFlagHasnochildren: (MBox*)mbox {
    mbox.noInferiors = @YES;
}
-(void) setMBoxFlagInbox: (MBox*)mbox {
    mbox.specialUse = @"Inbox";
}
-(void) setMBoxFlagDrafts: (MBox*)mbox {
    mbox.specialUse = @"Drafts";
}
-(void) setMBoxFlagSpam: (MBox*)mbox {
    mbox.specialUse = @"Spam";
}
-(void) setMBoxFlagSent: (MBox*)mbox {
    mbox.specialUse = @"Sent";
}
-(void) setMBoxFlagTrash: (MBox*)mbox {
    mbox.specialUse = @"Trash";
}
-(BOOL) setMailBox: (NSString *) fullPath AvailableFlags: (NSArray *) flagTokens {
    return YES;
}

-(BOOL) setMailBox: (NSString *) fullPath PermanentFlags: (NSArray *) flagTokens {
    return YES;
}

-(BOOL) setMailBox:(NSString *)fullPath serverHighestModSeq:(NSNumber *)theCount {
    return YES;
}

-(BOOL) setMailBox:(NSString *)fullPath serverMessageCount:(NSNumber *)theCount {
    return YES;
}

-(BOOL) setMailBox:(NSString *)fullPath serverRecentCount:(NSNumber *)theCount {
    return YES;
}

-(BOOL) setMailBox: (NSString *) fullPath Uidnext:(NSNumber *)uidNext {
    return  YES;
}

-(BOOL) setMailBox: (NSString *) fullPath Uidvalidity:(NSNumber *)uidValidity {
    return  YES;
}

-(BOOL) setMailBox: (NSString *) fullPath serverUnseen:(NSNumber *)unseen {
    return  YES;
}

-(BOOL) selectedMailBoxDeleteAllMessages: (NSError **) error {
    return YES;
}
-(NSSet*) allUIDsForSelectedMailBox {
    return [self.serverUids copy];
}
#pragma mark - Message
// Called from IMAPParsedResponse
-(BOOL) setMessage:(NSNumber *)uid propertiesFromDictionary:(NSDictionary *)aDictionary {
    
    [self.serverUids addObject: uid];
    
    return YES;
}


#pragma mark - utilities




@end
