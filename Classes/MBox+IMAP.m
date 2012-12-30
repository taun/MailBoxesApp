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

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

static const int ddLogLevel = LOG_LEVEL_WARN;

@implementation MBox (IMAP)


//TODO: deal with errors 
- (MBMessage *) findMessageForUID: (NSNumber *) uid {
    MBMessage * message = nil;
    
    __block NSManagedObjectContext *context = [self managedObjectContext];
    
    NSManagedObjectModel *model = [[context persistentStoreCoordinator] managedObjectModel];
    
    __block NSError *error = nil;
    
    NSDictionary *substitutionDictionary = 
    [NSDictionary dictionaryWithObjectsAndKeys: uid, @"aUID", self.accountReference, @"ACCOUNTOBJECT",nil];
    
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
        message = [fetchedObjects objectAtIndex: 0];
    }
    
    return message;
}


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
                theMessage = [NSEntityDescription
                              insertNewObjectForEntityForName:@"MBMessage"
                              inManagedObjectContext: context];
                
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
            theFlag = [NSEntityDescription
                       insertNewObjectForEntityForName:@"MBFlag"
                       inManagedObjectContext: [self managedObjectContext]];
            
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
    
    NSDictionary *substitutionDictionary = [NSDictionary dictionaryWithObjectsAndKeys: serverName, @"SNAME",nil];
    
    __block NSArray *fetchedObjects;
    
    [context performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [model fetchRequestFromTemplateWithName:@"MBFlagForSName"
                                         substitutionVariables:substitutionDictionary];
        
        fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    }];
    

    
    // ToDo deal with error
    // There should always be only one. Don't know what error to post if > 1
    if ( ([fetchedObjects count] == 1) ) {
        flag = [fetchedObjects objectAtIndex: 0];
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
    NSExpression *minExpression = [NSExpression expressionForFunction:@"min:" arguments:[NSArray arrayWithObject:keyPathExpression]];
    
    // Create an expression description using the minExpression and returning a date.
    NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
    
    // The name is the key that will be used in the dictionary for the return value.
    [expressionDescription setName:@"minUID"];
    [expressionDescription setExpression:minExpression];
    [expressionDescription setExpressionResultType:NSInteger64AttributeType];
    
    // Set the request's properties to fetch just the property represented by the expressions.
    [fetchRequest setPropertiesToFetch:[NSArray arrayWithObject:expressionDescription]];
    
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
            lowestUID = [[objects objectAtIndex:0] valueForKey:@"minUID"];
        }
    }
    
    //
    
    return lowestUID;
}




@end
