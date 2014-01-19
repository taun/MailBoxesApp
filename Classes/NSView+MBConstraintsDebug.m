//
//  NSView+MBConstraintsDebug.m
//  MailBoxes
//
//  Created by Taun Chapman on 10/31/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "NSView+MBConstraintsDebug.h"

@implementation NSView (MBConstraintsDebug)

- (NSArray*) mbAllConstraints {
    NSMutableArray* constraintsArray = [NSMutableArray array];
    [constraintsArray addObjectsFromArray: self.constraints];
    for (NSView* view in self.subviews) {
        [constraintsArray addObjectsFromArray: [view mbAllConstraints]];
        
    }
    return constraintsArray;
}

@end
