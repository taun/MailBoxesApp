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
    NSMutableOrderedSet* newSet = [self.childNodes mutableCopy];
    [newSet addObject: value];
    self.childNodes = [newSet copy];
}

- (void)addChildNodes:(NSOrderedSet *)values {
    NSMutableOrderedSet* newSet = [self.childNodes mutableCopy];
    [newSet unionOrderedSet: values];
    self.childNodes = [newSet copy];
}
@end
