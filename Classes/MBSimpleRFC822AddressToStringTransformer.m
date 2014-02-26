//
//  MBAddressToRFC822StringTransformer.m
//  MailBoxes
//
//  Created by Taun Chapman on 01/20/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBSimpleRFC822AddressToStringTransformer.h"
#import "MBMIME2047ValueTransformer.h"
#import "MBAddress+IMAP.h"
#import "SimpleRFC822Address.h"

#import "NSObject+MBShorthand.h"

@implementation MBSimpleRFC822AddressToStringTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}
/*
 takes SimpleRFC822Address or MBAddress 
 returns string
 */
- (id)transformedValue:(id)value {
    NSString* addressString;
    
    if ([value isKindOfClass:[MBAddress class]] || [value isKindOfClass:[SimpleRFC822Address class]]) {
        if ( [[value name] length] != 0) {
            addressString = [NSString stringWithFormat: @"\"%@\" <%@>", [value name], [value email]];
        } else {
            addressString = [NSString stringWithFormat: @"<%@>", [value email]];
        }
    } else {
        addressString = nil;
    }
    
    return addressString;
}
/* 
 takes a string,
 returns SimpleRFC822Address 
 */
- (id)reverseTransformedValue:(id)value {

    SimpleRFC822Address* rfcaddress;
    
    if ([value isKindOfClass: [NSString class]]) {
        NSString* addressString = [(NSString*)value stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if ([addressString isNonNilString]) {
            NSMutableCharacterSet* addressDelimiters = [NSMutableCharacterSet characterSetWithCharactersInString: @"<>"];
            [addressDelimiters formUnionWithCharacterSet: [NSCharacterSet whitespaceCharacterSet]];
            
            NSMutableCharacterSet* nameDelimiters = [NSMutableCharacterSet characterSetWithCharactersInString: @"\""];
            [nameDelimiters formUnionWithCharacterSet: [NSCharacterSet whitespaceCharacterSet]];
            
            // Find space between name and address "first last <mailbox@domain>"
            NSRange lastSpace = [addressString rangeOfString: @" " options: NSBackwardsSearch];
            
            rfcaddress = [SimpleRFC822Address new];

            if (lastSpace.location != NSNotFound) {
                rfcaddress.name =  [[addressString substringWithRange: NSMakeRange(0, lastSpace.location)]
                                    stringByTrimmingCharactersInSet: nameDelimiters];
                
                rfcaddress.email = [[addressString substringWithRange: NSMakeRange(lastSpace.location+1, addressString.length-lastSpace.location-1)]
                                    stringByTrimmingCharactersInSet: addressDelimiters];
            } else {
                // only have <mailbox@domain>
                rfcaddress.email = [addressString stringByTrimmingCharactersInSet: addressDelimiters];
            }
            
            if (rfcaddress.email) {
                NSMutableArray* subcomponents = [[rfcaddress.email componentsSeparatedByString: @"@"] mutableCopy];
                if (subcomponents.count > 1) {
                    rfcaddress.domain = [subcomponents lastObject];
                    [subcomponents removeLastObject];
                    rfcaddress.mailbox = [subcomponents componentsJoinedByString: @"@"];
                }
            }
        }
    }
    
    return rfcaddress;
}

@end
