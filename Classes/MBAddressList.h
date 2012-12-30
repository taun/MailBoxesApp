//
//  MBAddressList.h
//  MailBoxes
//
//  Created by Taun Chapman on 11/17/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MBTreeNode.h"

@class MBAddress;

@interface MBAddressList : MBTreeNode

@property (nonatomic, retain) NSSet *addresses;
@end

@interface MBAddressList (CoreDataGeneratedAccessors)

- (void)addAddressesObject:(MBAddress *)value;
- (void)removeAddressesObject:(MBAddress *)value;
- (void)addAddresses:(NSSet *)values;
- (void)removeAddresses:(NSSet *)values;

@end
