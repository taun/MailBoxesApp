//
//  NSObject+MBShorthand.m
//  MailBoxes
//
//  Created by Taun Chapman on 12/2/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import "NSObject+MBShorthand.h"

@implementation NSObject (MBShorthand)

-(BOOL) isNonZeroArray {
    BOOL result = NO;
    if ([self isKindOfClass: [NSArray class]]) {
        if ([(NSArray*)self count]>0) {
            result = YES;
        }
    }
    return result;
}

-(BOOL) isNonNilString {
    BOOL result = NO;
    if ([self isKindOfClass: [NSString class]]) {
        if ([(NSString*)self length]>0) {
            if (!([(NSString*)self caseInsensitiveCompare: @"NIL"] == NSOrderedSame)) {
                result = YES;
            }
        }
    }
    return result;
}
@end
