//
//  MBMessage+IntersectSetFix.m
//  MailBoxes
//
//  Created by Taun Chapman on 12/07/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import "MBMessage+IntersectSetFix.h"

@implementation MBMessage (IntersectSetFix)

- (void)addChildNodesObject:(MBMime *)value {
    NSMutableOrderedSet* newSet = [self.childNodes mutableCopy];
    [newSet addObject: value];
    self.childNodes = [newSet copy];
}

- (void)addChildNodes:(NSOrderedSet *)values {
    NSMutableOrderedSet* newSet = [self.childNodes mutableCopy];
    [newSet unionOrderedSet: values];
    self.childNodes = newSet;
}

@end
