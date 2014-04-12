//
//  MBAccount.h
//  MailBoxes
//
//  Created by Taun Chapman on 04/03/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MBTreeNode.h"

@class MBAccountTypes, MBUser, MBox;

@interface MBAccount : MBTreeNode

@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSNumber * messageQuanta;
@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSNumber * port;
@property (nonatomic, retain) NSNumber * priority;
@property (nonatomic, retain) NSString * server;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSNumber * useTLS;
@property (nonatomic, retain) NSNumber * connectionLimit;
@property (nonatomic, retain) MBAccountTypes *accountType;
@property (nonatomic, retain) NSSet *allNodes;
@property (nonatomic, retain) MBUser *user;
@end

@interface MBAccount (CoreDataGeneratedAccessors)

- (void)addAllNodesObject:(MBox *)value;
- (void)removeAllNodesObject:(MBox *)value;
- (void)addAllNodes:(NSSet *)values;
- (void)removeAllNodes:(NSSet *)values;

@end
