//
//  MBEncodedStringHexOctetTransformer.m
//  MailBoxes
//
//  Created by Taun Chapman on 02/11/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBEncodedStringHexOctetTransformer.h"
#import "MBEncodedString.h"
#import "NSString+IMAPConversions.h"

@implementation MBEncodedStringHexOctetTransformer

+ (Class)transformedValueClass {
    return [MBEncodedString class];
}

- (id)transformedValue:(id)anMBEncodedString {
    MBEncodedString* dehexedString;
    
    if ([anMBEncodedString isKindOfClass:[MBEncodedString class]]) {

        NSString* qpString = ((MBEncodedString*)anMBEncodedString).string;
        NSStringEncoding encoding = ((MBEncodedString*)anMBEncodedString).encoding;

        dehexedString.string = [qpString mdcStringFromQEncodedAsciiHexInCharset: encoding];
        dehexedString.encoding = encoding;
    }
    return dehexedString;
}


@end
