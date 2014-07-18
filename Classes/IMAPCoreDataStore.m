//
//  IMAPCoreDataStore.m
//  MailBoxes
//
//  Created by Taun Chapman on 9/28/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import "IMAPCoreDataStore.h"

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


static const int ddLogLevel = LOG_LEVEL_WARN;

@interface IMAPCoreDataStore ()

@property (nonatomic, strong, readwrite) NSManagedObjectContext *parentContext;
@property (nonatomic, strong, readwrite) NSManagedObjectContext *localManagedContext;
@property (nonatomic, strong, readwrite) MBAccount              *account;

@end

@implementation IMAPCoreDataStore

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
    if (_selectedMBox==nil && _mboxID != nil) {
        
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
    
    [self.localManagedContext performBlockAndWait:^{
        @try {
            BOOL success;
            NSError* error;
            [_localManagedContext commitEditing];
            success = [self.localManagedContext save: &error];
            if (!success) {
                // ToDo: add more detailed error reporting here. Need to show CoreData validation errors
                // and give a chance to go back and correct them. Ideally show validation errors earlier.
                
                [self handleManagedObjectContextSaveError: error];
            } else {
                DDLogWarn(@"Warning [%@:%@] Saved managedObjectContext",
                             NSStringFromClass([self class]), NSStringFromSelector(_cmd));
                
            }
        }
        @catch (NSException *exception) {
            //_NSCoreDataOptimisticLockingException ?
            DDLogError(@"Error [%@:%@] exception: %@",
                         NSStringFromClass([self class]), NSStringFromSelector(_cmd), exception);
        }
        @finally {
            
        }
    }];
    [self parentSave];
}
- (void) parentSave {
    
    [self.parentContext performBlockAndWait:^{
        @try {
            BOOL success;
            NSError* error;
            [_parentContext commitEditing];
            success = [self.parentContext save: &error];
            if (!success) {
                // ToDo: add more detailed error reporting here. Need to show CoreData validation errors
                // and give a chance to go back and correct them. Ideally show validation errors earlier.
                
                [self handleManagedObjectContextSaveError: error];
            } else {
                DDLogWarn(@"%@:%@ Saved managedObjectContext",
                             NSStringFromClass([self class]), NSStringFromSelector(_cmd));
                
            }
        }
        @catch (NSException *exception) {
            //_NSCoreDataOptimisticLockingException ?
            DDLogError(@"Error [%@:%@] exception: %@",
                         NSStringFromClass([self class]), NSStringFromSelector(_cmd), exception);
        }
        @finally {
            
        }
    }];
    
}
-(void) handleManagedObjectContextSaveError: (NSError*) error {
    // ToDo: add more detailed error reporting here. Need to show CoreData validation errors
    // and give a chance to go back and correct them. Ideally show validation errors earlier.
    
    NSMutableString *errorString = nil;
    NSInteger errorCode = [error code];
    if (errorCode == NSValidationMultipleErrorsError) {
        // For an NSValidationMultipleErrorsError, the original errors
        // are in an array in the userInfo dictionary for key NSDetailedErrorsKey
        NSArray *detailedErrors = [error userInfo][NSDetailedErrorsKey];
        
        // For this example, only present error messages for up to 3 validation errors at a time.
        
        NSUInteger numErrors = [detailedErrors count];
        errorString = [NSMutableString stringWithFormat:@"%lu validation errors have occurred", (unsigned long)numErrors];
        
        if (numErrors > 3) {
            [errorString appendFormat:@".\nThe first 3 are:\n"];
        }
        else {
            [errorString appendFormat:@":\n"];
        }
        NSUInteger i, displayErrors = numErrors > 3 ? 3 : numErrors;
        for (i = 0; i < displayErrors; i++) {
            [errorString appendFormat:@"%@\n",
             [detailedErrors[i] localizedDescription]];
        }
    } else if (errorCode == NSValidationMissingMandatoryPropertyError) {
        NSString* errorObject = [[[error userInfo] objectForKey: NSValidationObjectErrorKey] description];
        NSString* errorKey = [[[error userInfo] objectForKey: NSValidationKeyErrorKey] description];
        DDLogError(@"Error [%@:%@] Validation error when saving managedObjectContext", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
        DDLogError(@"Missing Key: %@; in Object: %@", errorKey, errorObject);
    } else {
        errorString = [NSMutableString stringWithFormat: @"%@>%@", [error localizedDescription], [error localizedFailureReason]];
        DDLogError(@"Error [%@:%@] unable to save managedObjectContext", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
        DDLogError(@"%@", errorString);
    }
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
-(MBox *) fetchMBox: (NSString *) fullPath {
    if ([self.selectedMBox.fullPath compare: fullPath] == NSOrderedSame) {
        return self.selectedMBox;
    } else {
        return [self.account fetchMBoxForPath: fullPath];
    }
}

-(MBox *) selectMailBox: (NSString *) fullPath {
    self.selectedMBox = [self.account fetchMBoxForPath: fullPath];
    self.selectedMBox.lastSelected = [NSDate date];
    self.selectedMBox.maxCachedUID = [self.selectedMBox.messages valueForKeyPath: @"@max.uid"];
    return self.selectedMBox;
}

-(BOOL) setMailBoxReadOnly: (NSString *) fullPath {
    MBox* mbox = [self fetchMBox: fullPath];
    mbox.isReadWrite = @NO;
    return YES;
}

-(BOOL) setMailBoxReadWrite: (NSString *) fullPath {
    MBox* mbox = [self fetchMBox: fullPath];
    mbox.isReadWrite = @YES;
    return YES;
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
    MBox* mbox = [self fetchMBox: fullPath];
    MBFlag *flag = nil;
    
    for (NSString *token in flagTokens) {
        NSSet *flags = [mbox valueForKey: @"availableFlags"];
        flag = [mbox getMBFlagWithServerAssignedName: token createIfMissing: YES];

        if (![flags containsObject: flag]) {
            [mbox addAvailableFlagsObject: flag];
        }
    }
    return YES;
}

-(BOOL) setMailBox: (NSString *) fullPath PermanentFlags: (NSArray *) flagTokens {
    MBox* mbox = [self fetchMBox: fullPath];
    MBFlag *flag = nil;
    
    for (NSString *token in flagTokens) {
        NSSet *flags = [mbox valueForKey: @"permanentFlags"];
        if (![flags containsObject: token]) {
            flag = [mbox getMBFlagWithServerAssignedName: token createIfMissing: YES];
            [mbox addPermanentFlagsObject: flag];
        }
    }
    return YES;
}

-(BOOL) setMailBox:(NSString *)fullPath serverHighestModSeq:(NSNumber *)theCount {
    MBox* mbox = [self fetchMBox: fullPath];
    mbox.serverHighestModSeq = theCount;
    return YES;
}

-(BOOL) setMailBox:(NSString *)fullPath serverMessageCount:(NSNumber *)theCount {
    MBox* mbox = [self fetchMBox: fullPath];
    mbox.serverMessages = theCount;
    return YES;
}

-(BOOL) setMailBox:(NSString *)fullPath serverRecentCount:(NSNumber *)theCount {
    MBox* mbox = [self fetchMBox: fullPath];
    mbox.serverRecent = theCount;
    return YES;
}

-(BOOL) setMailBox: (NSString *) fullPath Uidnext:(NSNumber *)uidNext {
    MBox* mbox = [self fetchMBox: fullPath];
    mbox.serverUIDNext = uidNext;
    return  YES;
}

-(BOOL) setMailBox: (NSString *) fullPath Uidvalidity:(NSNumber *)uidValidity {
    MBox* mbox = [self fetchMBox: fullPath];
    
    NSNumber *oldValidity = mbox.serverUIDValidity;
    if (oldValidity != uidValidity) {
        // If server UIDvalidity changes, then no message UIDs are valid 
        // and all messages need to be reloaded from scratch
        // this is done be reseting maxCachedUID to 0
        mbox.maxCachedUID = @0;
        mbox.serverUIDValidity = uidValidity;
    }
    return  YES;
}

-(BOOL) setMailBox: (NSString *) fullPath serverUnseen:(NSNumber *)unseen {
    MBox* mbox = [self fetchMBox: fullPath];
    mbox.serverUnseen = unseen;
    return  YES;
}

-(BOOL) selectedMailBoxDeleteAllMessages: (NSError **) error {
    MBox *mbox = self.selectedMBox;
    
    [self.localManagedContext performBlockAndWait:^{
        NSSet *allMessages = [mbox valueForKey: @"messages"];
        for (NSManagedObject *message in allMessages) {
            [self.localManagedContext deleteObject: message];
        }
        //return [self save: error]; // should this be "[[self localManagedContext] processPendingChanges];"?
        [_localManagedContext processPendingChanges];
    }];

    return YES;
}

-(NSSet*) allCachedUIDsForSelectedMailBox {
    NSSet* allUIDs;
//    [self.localManagedContext reset];
//    _selectedMBox = nil;
//    _account = nil;
//    
//    MBox* mbox = self.selectedMBox;
//    NSSet* messages = mbox.messages;
    
    allUIDs = [self.selectedMBox allUIDS];
    
    return allUIDs;
}

-(NSSet*) allCachedUIDsNotFullyCachedForSelectedMailBox {
    NSSet* allUIDs;
    
    allUIDs = [self.selectedMBox allUIDSForNotFullyCached];
    
    return allUIDs;
}

#pragma message "Was used in deprecated sync of IMAPClient"
-(NSNumber*) lowestUID {
    __block NSNumber* lowestUID = nil;
    MBox* selectedBox = self.selectedMBox;
    
    [self.localManagedContext performBlockAndWait:^{
        lowestUID = [selectedBox lowestUID];
    }];
    return lowestUID;
}

#pragma mark - Message
-(BOOL) setMessage:(NSNumber *)uid propertiesFromDictionary:(NSDictionary *)aDictionary {
    __block BOOL success = NO;
    MBox* selectedBox = self.selectedMBox;
    
    [self.localManagedContext performBlockAndWait:^{
        MBMessage *message = [selectedBox getMBMessageWithUID: uid createIfMissing: YES];
        [message setPropertiesFromDictionary: aDictionary];
//        selectedMBox.maxCachedUID = MAX(uid, selectedMBox.maxCachedUID);
    }];
    
    return success;
}
-(BOOL) newMessage:(NSNumber *)uid propertiesFromDictionary:(NSDictionary *)aDictionary {
    __block BOOL success = NO;
    MBox* selectedBox = self.selectedMBox;
    
    [self.localManagedContext performBlockAndWait:^{
        MBMessage *message = [selectedBox newMBMessageWithUID: uid];
        [message setPropertiesFromDictionary: aDictionary];
        //        selectedMBox.maxCachedUID = MAX(uid, selectedMBox.maxCachedUID);
    }];
    
    return success;
}


#pragma mark - utilities




@end
