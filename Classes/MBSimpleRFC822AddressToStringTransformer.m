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
#import <MoedaeMailPlugins/SimpleRFC822Address.h>
#import <MoedaeMailPlugins/NSString+IMAPConversions.h>

#import <MoedaeMailPlugins/NSObject+MBShorthand.h>

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
    SimpleRFC822Address* address;
    
    if ([value isKindOfClass:[MBAddress class]]) {
        address = [(MBAddress*)value newSimpleAddress];
    } else if ([value isKindOfClass:[SimpleRFC822Address class]]) {
        address = (SimpleRFC822Address*)value;
    }
    
    if (address) {
        addressString = [address stringSingleTopLevel];
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
        
        rfcaddress = [SimpleRFC822Address newFromString: value];//[(NSString*)value mdcSimpleRFC822Address];
        
    }
    
    return rfcaddress;
}

@end
