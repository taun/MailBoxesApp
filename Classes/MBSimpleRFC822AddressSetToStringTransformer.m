//
//  MBAddressesToRFC822StringTransformer.m
//  MailBoxes
//
//  Created by Taun Chapman on 01/20/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBSimpleRFC822AddressSetToStringTransformer.h"
#import "MBSimpleRFC822AddressToStringTransformer.h"

#import "SimpleRFC822Address.h"
#import "MBAddress+IMAP.h"

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
    
    NSValueTransformer* addressTranformer = [NSValueTransformer valueTransformerForName: VTMBSimpleRFC822AddressToStringTransformer];
    
    
    if ([value isKindOfClass:[NSSet class]]) {
        
        NSMutableArray* addressStringArray = [NSMutableArray new];
        
        for (id address in value) {
            NSString* addressString = @"";
            
            if ([address isKindOfClass: [MBAddress class]] || [address isKindOfClass:[SimpleRFC822Address class]]) {
                
                addressString = [addressTranformer transformedValue: address];

                [addressStringArray addObject: addressString];
            }
        }
        addressesString = [addressStringArray componentsJoinedByString: @", "];
        
     } else {
        addressesString = @"";
    }
    
    return addressesString;
}
/*
 takes comma separated string of email address like below
 "Nancy Reigel" <ndreigel@bellatlantic.net>, "'Carl, Davies'" <carl_davies99@yahoo.com>, "'Taun'" <taun@charcoalia.net>, "'Michael B. Parmet'" <mbparmet@parmetech.com>, <geminikc9@yahoo.com>, <richard.hankin@hankingroup.com>, <DBoscher@CNTUS.JNJ.COM>, <mark@mccay.com>, <canniff@canniff.net>, <ndreigel@verizon.net>, <monckma@yahoo.com>, "'Alicia Shultz'" <AliciaShultz@princetowncable.com>, "'Laurie'" <reelmom5@verizon.net>, "'Wagner, Tim [NCSUS]'" <twagner@ncsus.jnj.com>, <jppsd@msn.com>, <karen_vanbemmel@yahoo.com>

 Look for ">,"
 
 returns NSSet of SimpleRFC822Addresses
 
 Despite the following from the RFC
 "Writers of  mail-sending  (i.e.,  header-generating)  programs
 should realize that there is no network-wide definition of the
 effect of ASCII HT (horizontal-tab) characters on the  appear-
 ance  of  text  at another network host; therefore, the use of
 tabs in message headers, though permitted, is discouraged."
 
 We need to be able to handle tabs.
 */
- (id)reverseTransformedValue:(id)value {
    
    NSMutableSet* addresses = [NSMutableSet new];
    
    if ([value isKindOfClass: [NSString class]]) {
        NSString* noTabs = [(NSString*)value stringByReplacingOccurrencesOfString: @"\t" withString: @"  "];
        NSString* noSingleQuote = [noTabs stringByReplacingOccurrencesOfString: @"'" withString: @"  "];

        NSArray* addressesArray = [noSingleQuote componentsSeparatedByString: @">, "];
        
        NSMutableArray* fixedAddressesArray = [NSMutableArray new];
        for (NSString* address in addressesArray) {
            // put back the ">" removed by using the componentsSeparatedByString method with ">, "
            [fixedAddressesArray addObject: [NSString stringWithFormat: @"%@>", address]];
        }
        
        NSValueTransformer* addressTransformer = [NSValueTransformer valueTransformerForName: VTMBSimpleRFC822AddressToStringTransformer];
        
        for (NSString* addressString in fixedAddressesArray) {
            SimpleRFC822Address* rfcAddress = [addressTransformer reverseTransformedValue: addressString];
            if (rfcAddress) {
                [addresses addObject: rfcAddress];
            }
        }
    }
    
    return [addresses copy];
}

@end
