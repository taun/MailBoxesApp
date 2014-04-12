//
//  IMAPCoreDataStore.m
//  MailBoxes
//
//  Created by Taun Chapman on 9/28/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import "IMAPCoreDataStore.h"
#import "MailBoxesAppDelegate.h"

#import "MBAccount+IMAP.h"
#import "MBox+IMAP.h"
#import "MBMessage+IMAP.h"
#import "MBAddress+IMAP.h"
#import "MBMime+IMAP.h"
#import "MBMimeData+IMAP.h"

#import "NSManagedObject+Shortcuts.h"

#import "MBRFC2822.h"

#import <MoedaeMailPlugins/NSString+IMAPConversions.h>

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

static const int ddLogLevel = LOG_LEVEL_INFO;

@implementation IMAPCoreDataStore


@synthesize appDelegate;
@synthesize account;
@synthesize parentContext;
@synthesize localManagedContext;
@synthesize selectedMBox;

-(id) init {
    // Initialization code here.
    return [self initWithParentContext: nil AccountID: nil];
}

-(id) initWithParentContext: (NSManagedObjectContext*) pcontext AccountID: (NSManagedObjectID *) anAccount {
    assert(anAccount != nil);
    
    self = [super init];
    if (self) {
        appDelegate = (MailBoxesAppDelegate*)[[NSApplication sharedApplication] delegate];
        parentContext = pcontext;
        _accountID = anAccount;
        // We do not assign a local context yet because it may still be on the main thread
        localManagedContext = nil;
        selectedMBox = nil;
        account = nil;
    }
    return self;
}

#pragma mark - Core Data 
-(NSManagedObjectContext *) localManagedContext {
    if (localManagedContext==nil) {
        localManagedContext = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSPrivateQueueConcurrencyType];
        [self.localManagedContext setParentContext: parentContext];
        [self.localManagedContext setUndoManager:nil];
        [self.localManagedContext setMergePolicy: NSOverwriteMergePolicy];
//        [[NSNotificationCenter defaultCenter] addObserver:self
//               selector:@selector(mergeChanges:) 
//                   name:NSManagedObjectContextDidSaveNotification
//                 object:self.localManagedContext];

    }
    return localManagedContext;
}

-(MBAccount *) account {
    if (account==nil) {
        
        [self.localManagedContext performBlockAndWait:^{
            account = (MBAccount *)[localManagedContext objectWithID: _accountID];
        }];

    }
    return account;
}

- (BOOL) save: (NSError**) error {
    __block BOOL success;
    
    @try {
        [self.localManagedContext performBlockAndWait:^{
            [localManagedContext commitEditing];
            success = [self.localManagedContext save: error];
        }];

        

//        id mbapp = [[NSApplication sharedApplication] delegate];
//        [mbapp performSelectorOnMainThread: @selector(saveAction:) withObject: nil waitUntilDone: NO];

        
        if (!success) {
            // ToDo: add more detailed error reporting here. Need to show CoreData validation errors
            // and give a chance to go back and correct them. Ideally show validation errors earlier.
            
            NSMutableString *errorString = nil;
            NSInteger errorCode = [*error code];
            if (errorCode == NSValidationMultipleErrorsError) {
                // For an NSValidationMultipleErrorsError, the original errors
                // are in an array in the userInfo dictionary for key NSDetailedErrorsKey
                NSArray *detailedErrors = [*error userInfo][NSDetailedErrorsKey];
                
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
            } else {
                errorString = [NSMutableString stringWithFormat: @"%@>%@", [*error localizedDescription], [*error localizedFailureReason]];
            }
            DDLogVerbose(@"%@:%@ unable to save managedObjectContext",
                         NSStringFromClass([self class]), NSStringFromSelector(_cmd));
            DDLogVerbose(@"%@", errorString);
        } else {
            DDLogVerbose(@"%@:%@ Saved managedObjectContext", 
                         NSStringFromClass([self class]), NSStringFromSelector(_cmd));
            
        }
    }
    @catch (NSException *exception) {
        //_NSCoreDataOptimisticLockingException ?
        DDLogVerbose(@"%@:%@ exception: %@", 
                     NSStringFromClass([self class]), NSStringFromSelector(_cmd), exception);
    }
    @finally {
        
    }
    
    return success;    
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
        foundObject = (MBox*)[localManagedContext objectWithID: objectID];
    }];
    
    return foundObject;
}
-(MBMessage*) messageForObjectID:(NSManagedObjectID *)objectID {
    __block MBMessage* foundObject;
    
    [self.localManagedContext performBlockAndWait:^{
        foundObject = (MBMessage*)[localManagedContext objectWithID: objectID];
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
        if ([flagTokens containsObject: @"\\NoInferiors"]) {
            // flag folder
        } else if ([flagTokens containsObject: @"\\Marked"]) {
            //apply marked flag so sync can focus on marked folders first
            mbox.isMarked = @YES;
            
        } else if ([flagTokens containsObject: @"\\All"]) {
            //enable special use flag
            mbox.specialUse = @"All";
            
        } else if ([flagTokens containsObject: @"\\Inbox"]) {
            //enable special use flag
            mbox.specialUse = @"Inbox";
            
        } else if ([flagTokens containsObject: @"\\Drafts"]) {
            //enable special use flag
            mbox.specialUse = @"Drafts";
            
        } else if ([flagTokens containsObject: @"\\Sent"]) {
            //enable special use flag
            mbox.specialUse = @"Sent";
            
        } else if ([flagTokens containsObject: @"\\Trash"]) {
            //enable special use flag
            mbox.specialUse = @"Trash";
            
        } else if ([flagTokens containsObject: @"\\Spam"]) {
            //enable special use flag
            mbox.specialUse = @"Spam";
            
        } else if ([flagTokens containsObject: @"\\Flagged"]) {
            //enable special use flag 
            // What is this one for?
        }

    }
    return YES;
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
        // this is done be reseting lastSeenUID to 1
        mbox.lastSeenUID = @1;
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
        [localManagedContext processPendingChanges];
    }];

    return YES;
}

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
    }];
    
    return success;
}


#pragma mark - utilities




@end
