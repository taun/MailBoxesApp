//
//  MBUser.h
//  MailBoxes
//
//  Created by Taun Chapman on 02/20/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MBAccount, MBSidebar, MBViewPortal;

@interface MBUser : NSManagedObject

@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSSet *accounts;
@property (nonatomic, retain) NSOrderedSet *portals;
@property (nonatomic, retain) MBSidebar *sidebar;
@end

@interface MBUser (CoreDataGeneratedAccessors)

- (void)addAccountsObject:(MBAccount *)value;
- (void)removeAccountsObject:(MBAccount *)value;
- (void)addAccounts:(NSSet *)values;
- (void)removeAccounts:(NSSet *)values;

- (void)insertObject:(MBViewPortal *)value inPortalsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPortalsAtIndex:(NSUInteger)idx;
- (void)insertPortals:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePortalsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPortalsAtIndex:(NSUInteger)idx withObject:(MBViewPortal *)value;
- (void)replacePortalsAtIndexes:(NSIndexSet *)indexes withPortals:(NSArray *)values;
- (void)addPortalsObject:(MBViewPortal *)value;
- (void)removePortalsObject:(MBViewPortal *)value;
- (void)addPortals:(NSOrderedSet *)values;
- (void)removePortals:(NSOrderedSet *)values;
@end
