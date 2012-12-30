//
//  MBAccountTypes.h
//  MailBoxes
//
//  Created by Taun Chapman on 11/14/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MBAccount;

@interface MBAccountTypes : NSManagedObject

@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * mailSuffix;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * serverDomain;
@property (nonatomic, retain) NSString * services;
@property (nonatomic, retain) NSString * userNamePattern;
@property (nonatomic, retain) NSSet *accounts;
@end

@interface MBAccountTypes (CoreDataGeneratedAccessors)

- (void)addAccountsObject:(MBAccount *)value;
- (void)removeAccountsObject:(MBAccount *)value;
- (void)addAccounts:(NSSet *)values;
- (void)removeAccounts:(NSSet *)values;

@end
