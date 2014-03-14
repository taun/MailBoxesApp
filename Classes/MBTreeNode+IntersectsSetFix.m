//
//  MBTreeNode+IntersectsSetFix.m
//  MailBoxes
//
//  Created by Taun Chapman on 11/17/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import "MBTreeNode+IntersectsSetFix.h"

@implementation MBTreeNode (IntersectsSetFix)

+ (NSString *)entityName {
    return @"MBTreeNode";
}

- (void)addChildNodesObject:(MBTreeNode *)value {
    NSMutableOrderedSet* referenceSet = [self mutableOrderedSetValueForKey: @"childNodes"];
    [referenceSet addObject: value];
}

- (void)addChildNodes:(NSOrderedSet *)values {
    NSMutableOrderedSet* newSet = [self mutableOrderedSetValueForKey: @"childNodes"];
    [newSet unionOrderedSet: values];
}

- (void)addParentNodesObject:(MBTreeNode *)value {
    NSMutableOrderedSet* referenceSet = [self mutableOrderedSetValueForKey: @"parentNodes"];
    [referenceSet addObject: value];
}

- (void)addParentNodes:(NSOrderedSet *)values {
    NSMutableOrderedSet* newSet = [self mutableOrderedSetValueForKey: @"parentNodes"];
    [newSet unionOrderedSet: values];
}

@end
