//
//  MBTreeNode+IntersectsSetFix.m
//  MailBoxes
//
//  Created by Taun Chapman on 11/17/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import "MBTreeNode+IntersectsSetFix.h"

@implementation MBTreeNode (IntersectsSetFix)

- (void)addChildNodesObject:(MBTreeNode *)value {
    NSMutableOrderedSet* newSet = [self.childNodes mutableCopy];
    [newSet addObject: value];
    self.childNodes = [newSet copy];
}

- (void)addChildNodes:(NSOrderedSet *)values {
    NSMutableOrderedSet* newSet = [self.childNodes mutableCopy];
    [newSet unionOrderedSet: values];
    self.childNodes = newSet;
}

- (void)addParentNodesObject:(MBTreeNode *)value {
    NSMutableOrderedSet* newSet = [self.parentNodes mutableCopy];
    [newSet addObject: value];
    self.parentNodes = [newSet copy];
}

- (void)addParentNodes:(NSOrderedSet *)values {
    NSMutableOrderedSet* newSet = [self.parentNodes mutableCopy];
    [newSet unionOrderedSet: values];
    self.parentNodes = newSet;
}

@end
