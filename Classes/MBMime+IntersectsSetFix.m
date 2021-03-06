//
//  MBMime+IntersectsSetFix.m
//  MailBoxes
//
//  Created by Taun Chapman on 12/01/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import "MBMime+IntersectsSetFix.h"

@implementation MBMime (IntersectsSetFix)

- (void)addChildNodesObject:(MBMime *)value {
    NSMutableOrderedSet* referenceSet = [self mutableOrderedSetValueForKey: @"childNodes"];
    [referenceSet addObject: value];
}

- (void)addChildNodes:(NSOrderedSet *)values {
    NSMutableOrderedSet* newSet = [self mutableOrderedSetValueForKey: @"childNodes"];
    [newSet unionOrderedSet: values];
}
@end
