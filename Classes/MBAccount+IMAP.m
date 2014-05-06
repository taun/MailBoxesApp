//
//  IMAPAccount.m
//  MailBoxes
//
//  Created by Taun Chapman on 2/22/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import "MBAccount+IMAP.h"
#import "MBox+IMAP.h"
#import "NSManagedObject+Shortcuts.h"
#import "MailBoxesAppDelegate.h"

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

static const int ddLogLevel = LOG_LEVEL_WARN;

//Why was this here?
//@interface NSManagedObject (IMAP)   <TreeNode> 
//@end


@implementation MBAccount (IMAP)

+ (NSString *)entityName {
    return @"MBAccount";
}

+ (NSArray *)keysToBeCopied {
    static NSArray *keysToBeCopied = nil;
    if (keysToBeCopied == nil) {
        keysToBeCopied = @[@"name", @"username", @"password", @"server", 
                          @"port", @"address", @"desc", @"useTLS", 
                          @"priority", @"messageQuanta", @"accountType"];
    }
    return keysToBeCopied;
}

- (MBox *)getMBoxAtPath:(NSString *)path 
                withSeparator: (NSString *)separator 
  createIntermediateMBoxes:(BOOL)createIntermediates {
   
    MBox *node = nil;
         
    node = [self addNodePath: path separator: separator]; 
    
    return node;
}

- (MBox *) fetchMBoxForPath: (NSString *) aPath {
    return [self findNodeForFullPath: aPath];
}


/*
- (void) didTurnIntoFault {
    [_connection release];
    [super didTurnIntoFault];
}
*/

#pragma mark - encoding decoding

- (void)encodeWithCoder:(NSCoder *)coder {
//    for (NSString* key in [MBAccount keysToBeCopied]) {
//        <#statements#>
//    }
    NSURL* objectURL = [[self objectID] URIRepresentation];
    [coder encodeObject: [objectURL absoluteString] forKey: @"managedObjectURL"]; // is this use anywhere?
    [coder encodeObject: self.name forKey:@"name"];
    [coder encodeObject: self.desc forKey:@"desc"];
    [coder encodeObject: self.address forKey:@"address"];
    [coder encodeObject: self.username forKey:@"username"];
    [coder encodeObject: self.server forKey:@"server"];
    [coder encodeObject: self.port forKey:@"port"];
    [coder encodeObject: self.useTLS forKey:@"useTLS"];
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
            self.address = [coder decodeObjectForKey: @"address"];
            self.username = [coder decodeObjectForKey: @"username"];
            self.server = [coder decodeObjectForKey: @"server"];
            self.port = [coder decodeObjectForKey: @"port"];
            self.useTLS = [coder decodeObjectForKey: @"useTLS"];
        }
    }
    return self;
}


- (NSUInteger)count {
    DDLogVerbose(@"Count called");
    NSUInteger children = [[self childNodes] count];
    return children;
}

#pragma mark - Private Undeclared
/*!
 check if node exists and if so return node
 need to search by account, fullPath
 
 @param aPath the MBox fullPath. "/root/intermediates/MBoxName"
 
 @result returns the node if found or nil.
 */
- (MBox *) findNodeForFullPath: (NSString *) aPath {
    MBox * node = nil;
    
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSManagedObjectModel *model = [[context persistentStoreCoordinator] managedObjectModel];
    
    __block NSError *error = nil;
    
    NSDictionary *substitutionDictionary =
    @{@"PATH": aPath, @"ACCOUNTOBJECT": self};
    
    NSFetchRequest *fetchRequest =
    [model fetchRequestFromTemplateWithName:@"MBoxForPath"
                      substitutionVariables:substitutionDictionary];
    
    __block NSArray *fetchedObjects;
    
    [self.managedObjectContext performBlockAndWait:^{
        fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    }];
    
    // ToDo deal with error
    // There should always be only one. Don't know what error to post if > 1
    if ( ([fetchedObjects count] == 1) ) {
        node = fetchedObjects[0];
    }
    
    return node;
}

- (NSArray *) fetchMissingChildren {
    
    __block NSArray *fetchedObjects;
    
    [self.managedObjectContext performBlockAndWait:^{
        NSManagedObjectContext *context = [self managedObjectContext];
        
        NSManagedObjectModel *model = [[context persistentStoreCoordinator] managedObjectModel];
        
        NSError *error = nil;
        
        NSDictionary *substitutionDictionary =
        @{@"ACCOUNTOBJECT": self};
        
        NSFetchRequest *fetchRequest =
        [model fetchRequestFromTemplateWithName:@"MBFoldersNeedingChildren"
                          substitutionVariables:substitutionDictionary];
        fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    }];
    
    return fetchedObjects;
}

/*!
 check if root or node exists?
 if root or node exists, create node
 else call same with subPath
 recurse until root or node exists
 
 Create alternative version of addNodePath:
 which uses relationship sets rather than fetches
 to check for existance of folder????
 
 @param aPath the MBox fullPath. "/root/intermediates/MBoxName"
 @param pathSeparator mail server dependant path separation character such as '/'
 @return returns the node if found or nil.
 */
- (MBox *) addNodePath: (NSString *) aPath separator:(NSString *)pathSeparator {
    
    // check if root or node exists?
    //   if root or node exists, create node
    //   else call same with subPath
    // recurse until root or node exists
    NSManagedObject *parent = nil;
    MBox *node = nil;
    
    if ((node = [self findNodeForFullPath: aPath]) == nil){
        // if node doesn't exist, can add the node
        
        NSArray *subFolders = [aPath componentsSeparatedByString: pathSeparator];
        
        NSString *newName = [subFolders lastObject];
        
        if (([subFolders count] > 1)) {
            // check for pre-existence of parentNodes
            NSRange indexPathRange;
            indexPathRange.location = 0;
            indexPathRange.length = [subFolders count] - 1;
            
            NSArray *indexPathArray = [subFolders subarrayWithRange: indexPathRange];
            NSString *indexPath = [indexPathArray componentsJoinedByString: pathSeparator];
            
            parent = [self findNodeForFullPath: indexPath];
            if (parent == nil) {
                parent = [self addNodePath: indexPath separator: pathSeparator];
            }
        }
        
        // create a new node.
        node = [MBox insertNewObjectIntoContext: [self managedObjectContext]];
        
        node.fullPath = aPath;
        node.pathSeparator = pathSeparator;
        node.name = newName;
        node.accountReference = self;
        node.imageName = MBoxImageName;
        //node.parentNodes = [NSOrderedSet orderedSetWithObjects: (MBox  *)parent, nil];
        node.isLeaf = @YES;
        
        
        // add node to parent set.
        if (parent == nil) parent = self;
        // parent might be MBox or MBAccount
        MBTreeNode* parentNode = (MBTreeNode*)parent;
        NSMutableOrderedSet* childNodes = [parent mutableOrderedSetValueForKey: @"childNodes"];
        [childNodes addObject: node];
        [parentNode setIsLeaf: @NO];
        
    }
    return node;
}

@end
