//
//  MBAddressesToRFC822StringTransformer.h
//  MailBoxes
//
//  Created by Taun Chapman on 01/20/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#define VTMBSimpleRFC822AddressSetToStringTransformer @"MBSimpleRFC822AddressSetToStringTransformer"

/*!
 Converts a NSSet of MBAddress or SimpleRFC822Address and converts to a long string representation of the addresses.
 The reverseTransformedVale: takes a long NSString of addresses and converts to an NSSet of SimpleRFC822Address.
 
 Wraps SimpleRFC822Address methods for use in the UI.
 */
@interface MBSimpleRFC822AddressSetToStringTransformer : NSValueTransformer

@end
