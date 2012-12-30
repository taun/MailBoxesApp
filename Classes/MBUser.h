//
//  MBUser.h
//  MailBoxes
//
//  Created by Taun Chapman on 11/14/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MBAccount, MBSidebar, MBViewPortal;

@interface MBUser : NSManagedObject

@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSSet *portals;
@property (nonatomic, retain) MBSidebar *sidebar;
@property (nonatomic, retain) NSSet *accounts;
@end

@interface MBUser (CoreDataGeneratedAccessors)

- (void)addPortalsObject:(MBViewPortal *)value;
- (void)removePortalsObject:(MBViewPortal *)value;
- (void)addPortals:(NSSet *)values;
- (void)removePortals:(NSSet *)values;

- (void)addAccountsObject:(MBAccount *)value;
- (void)removeAccountsObject:(MBAccount *)value;
- (void)addAccounts:(NSSet *)values;
- (void)removeAccounts:(NSSet *)values;

@end
