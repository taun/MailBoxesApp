//
//  MBSidebar+Accessors.m
//  MailBoxes
//
//  Created by Taun Chapman on 11/14/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import "MBSidebar+Accessors.h"
#import "MBGroup+Shorthand.h"

#import "NSManagedObject+Shortcuts.h"

//@interface MBSidebar ()
//
//-(MBGroup*) groupIdentifiedBy: (NSString*) identifier;
//
//@end

@implementation MBSidebar (Accessors)

+ (NSString *)entityName {
    return @"MBSidebar";
}



/*!
 Private convenience method
 
 @param identifier NSString
 */
-(MBGroup*) groupIdentifiedBy: (NSString*) identifier {
    NSOrderedSet* groups = self.childNodes;
    MBGroup* result = nil;
    for (MBGroup* group in groups) {
        if ([group.identifier compare: identifier] == NSOrderedSame) {
            result = group;
        }
    }
    return result;    
}

-(MBGroup*) addGroup: (NSString *)identifier name:(NSString *)aName {
    MBGroup* newGroup = [MBGroup insertNewObjectIntoContext: self.managedObjectContext];
    newGroup.name = aName;
    newGroup.identifier = identifier;
    NSMutableOrderedSet* childNodes = [self mutableOrderedSetValueForKey: @"childNodes"];
    [childNodes addObject: newGroup];
    return newGroup;
}

-(MBGroup*) accountGroup {
    return [self groupIdentifiedBy: MBGroupAccountsIdentifier];
}

-(NSOrderedSet*) accounts {
    return [[self accountGroup] childNodes];
}

-(MBGroup*) smartFoldersGroup {
    return [self groupIdentifiedBy: MBGroupSmartFoldersIdentifier];
}

-(NSOrderedSet*) smartFolders {
    return [[self smartFoldersGroup] childNodes];
}

-(MBGroup*) favoritesGroup {
    return [self groupIdentifiedBy: MBGroupFavoritesIdentifier];
}

-(NSOrderedSet*) favorites {
    return [[self favoritesGroup] childNodes];
}

-(MBGroup*) listsGroup {
    return [self groupIdentifiedBy: MBGroupListsIdentifier];
}

-(NSOrderedSet*) lists {
    return [[self listsGroup] childNodes];
}
@end
