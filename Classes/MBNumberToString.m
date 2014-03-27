//
//  MBNumberToString.m
//  MailBoxes
//
//  Created by Taun Chapman on 02/25/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBNumberToString.h"

@implementation MBNumberToString

+ (Class)transformedValueClass {
    return [NSString class];
}


-(id) transformedValue:(id)value {
    NSString* theString;
    
    if ([value isKindOfClass:[NSNumber class]]) {
        // should be a string
        NSNumber* theNumber = (NSNumber*)value;
        theString = [theNumber stringValue];
    } else {
        theString = @"0";
    }
    return theString;
}

@end
