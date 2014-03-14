//
//  MBAddressesToRFC822StringTransformer.m
//  MailBoxes
//
//  Created by Taun Chapman on 01/20/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBSimpleRFC822AddressSetToStringTransformer.h"
#import "MBSimpleRFC822AddressToStringTransformer.h"

#import "MBAddress+IMAP.h"

#import <MoedaeMailPlugins/SimpleRFC822Address.h>
#import <MoedaeMailPlugins/NSString+IMAPConversions.h>
#import <MoedaeMailPlugins/NSObject+MBShorthand.h>

@implementation MBSimpleRFC822AddressSetToStringTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

/*
 takes NSSet of MBAddresses or SimpleRFC822Addresses
 return comma separated string
 */
- (id)transformedValue:(id)value {
    NSString* addressesString;
    
    if ([value isKindOfClass:[NSSet class]]) {
        
        NSMutableArray* addressStringArray = [NSMutableArray new];
        
        for (id address in value) {
            NSString* addressString = @"";
            
            if ([address isKindOfClass: [MBAddress class]] || [address isKindOfClass:[SimpleRFC822Address class]]) {
                
                addressString = [address stringRFC822AddressFormat];

                [addressStringArray addObject: addressString];
            }
        }
        addressesString = [addressStringArray componentsJoinedByString: @", "];
        
     } else {
        addressesString = nil;
    }
    
    return addressesString;
}
/*!
 Takes an RFC5322 string of email address like below.
 Assumes original header string is unfolded and comments removed.
 
 "Nancy Reigel" <ndreigel@bellatlantic.net>, "'Carl, Davies'" <carl_davies99@yahoo.com>, "'Taun'" <taun@charcoalia.net>, "'Michael B. Parmet'" <mbparmet@parmetech.com>, <geminikc9@yahoo.com>, <richard.hankin@hankingroup.com>, <DBoscher@CNTUS.JNJ.COM>, <mark@mccay.com>, <canniff@canniff.net>, <ndreigel@verizon.net>, <monckma@yahoo.com>, "'Alicia Shultz'" <AliciaShultz@princetowncable.com>, "'Laurie'" <reelmom5@verizon.net>, "'Wagner, Tim [NCSUS]'" <twagner@ncsus.jnj.com>, <jppsd@msn.com>, <karen_vanbemmel@yahoo.com>
 
 @returns NSSet of SimpleRFC822Addresses
 
 Despite the following from the RFC
 "Writers of  mail-sending  (i.e.,  header-generating)  programs
 should realize that there is no network-wide definition of the
 effect of ASCII HT (horizontal-tab) characters on the  appear-
 ance  of  text  at another network host; therefore, the use of
 tabs in message headers, though permitted, is discouraged."
 
 We need to be able to handle tabs.
 
 
 RFC 5322 Supercedes 2822
 ------------------------
 
 see [NSScanner mdcScanRfc822Address] for address spec.
 
 
 */


- (id)reverseTransformedValue:(id)value {
    
    NSMutableSet* addresses = [NSMutableSet new];
    
    if ([value isKindOfClass: [NSString class]]) {
        NSString* noTabs = [(NSString*)value stringByReplacingOccurrencesOfString: @"\t" withString: @"  "];
        NSString* noSingleQuote = [noTabs stringByReplacingOccurrencesOfString: @"'" withString: @""];
        NSString* trimmedAddressString = [noSingleQuote stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];

        if ([trimmedAddressString isNonNilString]) {
            NSArray* addressesArray = [trimmedAddressString componentsSeparatedByString: @">, "];
            
            NSMutableArray* fixedAddressesArray = [NSMutableArray new];
            for (NSString* address in addressesArray) {
                // put back the ">" removed by using the componentsSeparatedByString method with ">, "
                trimmedAddressString = [address stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if ([trimmedAddressString isNonNilString]) {
                    [fixedAddressesArray addObject: [NSString stringWithFormat: @"%@>", address]];
                }
            }
                        
            for (NSString* addressString in fixedAddressesArray) {
                SimpleRFC822Address* rfcAddress = [addressString mdcSimpleRFC822Address];
                if (rfcAddress) {
                    [addresses addObject: rfcAddress];
                }
            }
        }
    }
    
    return [addresses copy];
}

@end
