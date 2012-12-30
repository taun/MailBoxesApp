//
//  MBLabel.h
//  MailBoxes
//
//  Created by Taun Chapman on 11/14/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MBTreeNode.h"

@class MBMessage;

@interface MBLabel : MBTreeNode

@property (nonatomic, retain) NSData * color;
@property (nonatomic, retain) NSString * serverAssignedName;
@property (nonatomic, retain) NSSet *messages;
@end

@interface MBLabel (CoreDataGeneratedAccessors)

- (void)addMessagesObject:(MBMessage *)value;
- (void)removeMessagesObject:(MBMessage *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

@end
