//
//  MBMIME2047ValueTransformer.m
//  MailBoxes
//
//  Created by Taun Chapman on 09/16/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBMIME2047ValueTransformer.h"
#import "NSString+IMAPConversions.h"


static NSRegularExpression *regexEncodingFields;
static NSRegularExpression *regexQSpaces;


@implementation MBMIME2047ValueTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}


- (id)transformedValue:(id)anAsciiEncodedString {
    
    NSString* returnString;
    

    returnString = [(NSString*)anAsciiEncodedString mdcStringByDecodingRFC2047];
    
    
    return returnString;
}

#pragma message "TODO: reverseTransform"

@end
