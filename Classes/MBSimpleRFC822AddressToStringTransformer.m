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
            addressString = [NSString stringWithFormat: @"%@ <%@>", [value name], [value email]];
        } else {
            addressString = [NSString stringWithFormat: @"%@", [value email]];
        }
    } else {
        addressString = @"";
    }
    
    return addressString;
}
/* 
 takes a string,
 returns SimpleRFC822Address 
 */
- (id)reverseTransformedValue:(id)value {

    SimpleRFC822Address* rfcaddress = [SimpleRFC822Address new];
    
    if ([value isKindOfClass: [NSString class]]) {
        NSString* addressString = [(NSString*)value stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        NSRange lastSpace = [addressString rangeOfString: @" " options: NSBackwardsSearch];
        
        if (lastSpace.location == NSNotFound) {
            rfcaddress.email = addressString;
        } else {
            rfcaddress.email = [[[addressString substringWithRange: NSMakeRange(lastSpace.location+1, addressString.length-lastSpace.location-1)]
                                 stringByReplacingOccurrencesOfString: @"<" withString: @""]
                                stringByReplacingOccurrencesOfString: @">" withString: @""];
            rfcaddress.name =  [[addressString substringWithRange: NSMakeRange(0, lastSpace.location)] stringByReplacingOccurrencesOfString: @"\"" withString: @""];
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
    
    return rfcaddress;
}

@end
