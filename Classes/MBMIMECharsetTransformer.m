//
//  MBMIMECharsetTransformer.m
//  MailBoxes
//
//  Created by Taun Chapman on 10/16/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBMIMECharsetTransformer.h"

static NSDictionary *_charsetMap;

@implementation MBMIMECharsetTransformer

+ (Class)transformedValueClass {
    return [NSNumber class];
}

+(void)initialize {
    _charsetMap = @{@"US-ASCII": @(NSASCIIStringEncoding),
                    @"UTF-8": @(NSUTF8StringEncoding),
                    @"ISO-8859-1": @(NSISOLatin1StringEncoding),
                    @"KOI8-R": @(NSWindowsCP1251StringEncoding),
                    @"US-ASCII2": @(NSNonLossyASCIIStringEncoding)};
}

-(id) transformedValue:(id)value {
    NSNumber* nsDomainCharset;
    
    if ([value isKindOfClass:[NSString class]]) {
        // should be a string
        NSString* upperCaseMimeCharset = [value uppercaseString];
        nsDomainCharset = [_charsetMap objectForKey: upperCaseMimeCharset];
    }
    return nsDomainCharset;
}
@end
