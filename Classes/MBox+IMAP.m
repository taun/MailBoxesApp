//
//  MBox+IMAP.m
//  MailBoxes
//
//  Created by Taun Chapman on 2/24/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import "MBox+IMAP.h"
#import "MBMessage+IMAP.h"
#import "MBFlag+IMAP.h"
#import <MoedaeMailPlugins/MBoxProxy.h>
#import "MBAccount+IMAP.h"
#import "MailBoxesAppDelegate.h"

#import "NSManagedObject+Shortcuts.h"

static const int ddLogLevel = LOG_LEVEL_WARN;

@implementation MBox (IMAP)

+ (NSString *)entityName {
    return @"MBox";
}


- (void)encodeWithCoder:(NSCoder *)coder {
    //    for (NSString* key in [MBAccount keysToBeCopied]) {
    //        <#statements#>
    //    }
    NSURL* objectURL = [[self objectID] URIRepresentation];
    [coder encodeObject: [objectURL absoluteString] forKey: @"managedObjectURL"];
    [coder encodeObject: self.name forKey:@"name"];
    [coder encodeObject: self.desc forKey:@"desc"];
    [coder encodeObject: self.fullPath forKey:@"fullPath"];
    [coder encodeObject: self.uid forKey:@"uid"];
    //    [coder encodeFloat:magnification forKey:@"MVMagnification"];
}

- (id) initWithCoder:(NSCoder *)coder {
    NSManagedObjectContext* moc = [(MailBoxesAppDelegate*)[NSApp delegate] mainObjectContext];
    if (moc) {
        self = [NSEntityDescription
                insertNewObjectForEntityForName: NSStringFromClass([self class])
                inManagedObjectContext: moc];
        if (self) {
            self.name = [coder decodeObjectForKey: @"name"];
            self.desc = [coder decodeObjectForKey: @"desc"];
            self.fullPath = [coder decodeObjectForKey: @"fullPath"];
            self.uid = [coder decodeObjectForKey: @"uid"];
        }
    }
    return self;
}

-(MBoxProxy*) asMBoxProxy {
    MBAccount* account = self.accountReference;

    MBoxProxy* proxy = [MBoxProxy new];
    proxy.name = self.name;
    proxy.desc = self.desc;
    proxy.fullPath = self.fullPath;
    proxy.uid = self.uid;
    proxy.objectURL = [self.objectID URIRepresentation];
    proxy.accountIdentifier = account.identifier;
    return proxy;
}

-(NSSet*) allUIDS {
    __block NSMutableSet* uids;

    NSManagedObjectContext *context = [self managedObjectContext];
    
    [context performBlockAndWait:^{
    
        NSManagedObjectModel *model = [[context persistentStoreCoordinator] managedObjectModel];
    
        NSError *error = nil;
    
        NSDictionary *substitutionDictionary = @{@"MBOXOBJECT": self};
    
        NSArray *fetchedObjects;
        NSFetchRequest *fetchRequest = [model fetchRequestFromTemplateWithName:@"MBUIDsForMBox"
                      substitutionVariables:substitutionDictionary];
    
        NSEntityDescription* entity = [[model entitiesByName] objectForKey: @"MBMessage"];
        NSDictionary * entityProperties = [entity propertiesByName];
        NSPropertyDescription * nameInitialProperty = [entityProperties objectForKey:@"uid"];
        NSArray * tempPropertyArray = [NSArray arrayWithObject:nameInitialProperty];

        [fetchRequest setResultType: NSDictionaryResultType]; // This is redundant and set in IB CD model but maybe build folder needed cleaning?
        [fetchRequest setPropertiesToFetch: tempPropertyArray];
        [fetchRequest setShouldRefreshRefetchedObjects: YES];
        [fetchRequest setFetchLimit: 0];
        [fetchRequest setSortDescriptors: @[[[NSSortDescriptor alloc] initWithKey: @"uid" ascending:YES]]];
//        [fetchRequest setIncludesPendingChanges: YES]; // not valid with NSDictionaryResultType
    
        fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];

        if (fetchedObjects.count > 0) {
            uids = [NSMutableSet setWithCapacity: fetchedObjects.count];
        }
        for (NSDictionary* dictEntry in fetchedObjects) {
            [uids addObject: [dictEntry objectForKey: @"uid"]];
        }
    }];
    
    
    // ToDo deal with error
    // There should always be only one. Don't know what error to post if > 1

    return [uids copy];
}
//
-(NSSet*) allUIDSForNotFullyCached {
    __block NSMutableSet* uids;
    
    NSManagedObjectContext *context = [self managedObjectContext];
    
    [context performBlockAndWait:^{
        
        NSManagedObjectModel *model = [[context persistentStoreCoordinator] managedObjectModel];
        
        NSError *error = nil;
        
        NSDictionary *substitutionDictionary = @{@"MBOXOBJECT": self};
        
        NSArray *fetchedObjects;
        NSFetchRequest *fetchRequest = [model fetchRequestFromTemplateWithName:@"MBUIDsNotFullyCachedForMBox"
                                                         substitutionVariables:substitutionDictionary];
        
        NSEntityDescription* entity = [[model entitiesByName] objectForKey: @"MBMessage"];
        NSDictionary * entityProperties = [entity propertiesByName];
        NSPropertyDescription * nameInitialProperty = [entityProperties objectForKey:@"uid"];
        NSArray * tempPropertyArray = [NSArray arrayWithObject:nameInitialProperty];
        
        [fetchRequest setResultType: NSDictionaryResultType]; // This is redundant and set in IB CD model but maybe build folder needed cleaning?
        [fetchRequest setPropertiesToFetch: tempPropertyArray];
        
        fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
        
        if (fetchedObjects.count > 0) {
            uids = [NSMutableSet setWithCapacity: fetchedObjects.count];
        }
        for (NSDictionary* dictEntry in fetchedObjects) {
            [uids addObject: [dictEntry objectForKey: @"uid"]];
        }
    }];
    
    
    // ToDo deal with error
    // There should always be only one. Don't know what error to post if > 1
    
    return [uids copy];
}
#pragma message "TODO: deal with errors "
- (MBMessage *) findMessageForUID: (NSNumber *) uid {
    MBMessage * message = nil;
    
    __block NSManagedObjectContext *context = [self managedObjectContext];
    
    NSManagedObjectModel *model = [[context persistentStoreCoordinator] managedObjectModel];
    
    __block NSError *error = nil;
    
    NSDictionary *substitutionDictionary = 
    @{@"MBOXOBJECT": self, @"aUID": uid};
    
    NSFetchRequest *fetchRequest = 
    [model fetchRequestFromTemplateWithName:@"MBMessageForUID"
                      substitutionVariables:substitutionDictionary];
    
    __block NSArray *fetchedObjects;
    
    [context performBlockAndWait:^{
        fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    }];

    
    // ToDo deal with error
    // There should always be only one. Don't know what error to post if > 1
    if ( ([fetchedObjects count] == 1) ) {
        message = fetchedObjects[0];
    }
    
    return message;
}

#pragma message "There is an optimisation assumption here that new UIDs will always be fetched from lowest to highest."
- (MBMessage *)getMBMessageWithUID:(NSNumber *)uid 
                   createIfMissing:(BOOL)create {
    
    NSManagedObjectContext *context = [self managedObjectContext];
    
    __block MBMessage *theMessage = nil;
    
    [context performBlockAndWait:^{
        if (self.lastChangedMessage == nil || self.lastChangedMessage.uid != uid) {
            // message not in cache
            theMessage = [self findMessageForUID: uid];
            
            if (theMessage == nil && create) {
                // message was not found and needs to be created
                theMessage = [MBMessage insertNewObjectIntoContext: context];
                
                theMessage.uid = uid;
                [self addMessagesObject: theMessage];
                
            }
            self.lastChangedMessage = theMessage;
            
        } else if (self.lastChangedMessage.uid == uid) {
            // message cached
            theMessage = self.lastChangedMessage;
        }
    }];

    
    // create a new message.
    
    return theMessage;
}
- (MBMessage *)newMBMessageWithUID:(NSNumber *)uid {
    
    NSManagedObjectContext *context = [self managedObjectContext];
    
    __block MBMessage *theMessage = nil;
    
    [context performBlockAndWait:^{
        theMessage = [MBMessage insertNewObjectIntoContext: context];
        
        theMessage.uid = uid;
        [self addMessagesObject: theMessage];
        
        self.lastChangedMessage = theMessage;
        
    }];
    
    
    // create a new message.
    
    return theMessage;
}

- (void)removeAllCachedMessages {
    __block NSManagedObjectContext *context = [self managedObjectContext];
    
    [context performBlockAndWait:^{
        NSSet *allMessages = [self messages];
        for (NSManagedObject *message in allMessages) {
            [context deleteObject: message];
        }
    }];
}

- (MBFlag *)getMBFlagWithServerAssignedName: (NSString *) serverName 
                             createIfMissing:(BOOL)create {
    
    __block NSManagedObjectContext *context = [self managedObjectContext];
    
    __block MBFlag *theFlag;
    
    theFlag = [self findFlagForServerName: serverName];
    
    if (theFlag == nil && create) {
        // message was not found and needs to be created
        [context performBlockAndWait:^{
            theFlag = [MBFlag insertNewObjectIntoContext: [self managedObjectContext]];
            
            theFlag.serverAssignedName = serverName;
        }];
    }
    // create a new message.
    
    return theFlag;
}

- (MBFlag *) findFlagForServerName: (NSString *) serverName {
    MBFlag * flag = nil;
    
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSManagedObjectModel *model = [[context persistentStoreCoordinator] managedObjectModel];
    
    __block NSError *error = nil;
    
    NSDictionary *substitutionDictionary = @{@"SNAME": serverName};
    
    __block NSArray *fetchedObjects;
    
    [context performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [model fetchRequestFromTemplateWithName:@"MBFlagForSName"
                                         substitutionVariables:substitutionDictionary];
        
        fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    }];
    

    
    // ToDo deal with error
    // There should always be only one. Don't know what error to post if > 1
    if ( ([fetchedObjects count] == 1) ) {
        flag = fetchedObjects[0];
    }
    
    return flag;
}

-(NSNumber*) lowestUID {
    NSNumber* lowestUID = nil;
    
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName: @"MBMessage"];
    [fetchRequest setShouldRefreshRefetchedObjects: YES];
    
    // Specify that the request should return dictionaries.
    [fetchRequest setResultType:NSDictionaryResultType];
    
    // Only use messages in selected MBox
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"mbox == %@", self];
    [fetchRequest setPredicate:predicate];
    
    // Create an expression for the key path.
    NSExpression *keyPathExpression = [NSExpression expressionForKeyPath:@"uid"];
    
    // Create an expression to represent the minimum value at the key path 'creationDate'
    NSExpression *minExpression = [NSExpression expressionForFunction:@"min:" arguments:@[keyPathExpression]];
    
    // Create an expression description using the minExpression and returning a date.
    NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
    
    // The name is the key that will be used in the dictionary for the return value.
    [expressionDescription setName:@"minUID"];
    [expressionDescription setExpression:minExpression];
    [expressionDescription setExpressionResultType:NSInteger64AttributeType];
    
    // Set the request's properties to fetch just the property represented by the expressions.
    [fetchRequest setPropertiesToFetch:@[expressionDescription]];
    
    // Execute the fetch.
     NSError *error = nil;
     NSArray* objects;
    
    objects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (objects == nil) {
        // Handle the error.
    }
    else {
        if ([objects count] > 0) {
            DDLogVerbose(@"Minimum UID: %@", [[objects objectAtIndex:0] valueForKey:@"minUID"]);
            lowestUID = [objects[0] valueForKey:@"minUID"];
        }
    }
    
    //
    
    return lowestUID;
}




@end
