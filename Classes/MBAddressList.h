//
//  MBAddressList.h
//  MailBoxes
//
//  Created by Taun Chapman on 03/19/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MBTreeNode.h"

@class MBAddress;

@interface MBAddressList : MBTreeNode

@property (nonatomic, retain) NSSet *group;
@end

@interface MBAddressList (CoreDataGeneratedAccessors)

- (void)addGroupObject:(MBAddress *)value;
- (void)removeGroupObject:(MBAddress *)value;
- (void)addGroup:(NSSet *)values;
- (void)removeGroup:(NSSet *)values;

@end
