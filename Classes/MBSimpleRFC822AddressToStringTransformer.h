//
//  MBAddressToRFC822StringTransformer.h
//  MailBoxes
//
//  Created by Taun Chapman on 01/20/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#define VTMBSimpleRFC822AddressToStringTransformer @"MBSimpleRFC822AddressToStringTransformer"

/*!
 Transform a potential list of Addresses to a string with ONE address for display in a UI.
 At some point, will be replaced with an AddressView rather than using a textField.
 */
@interface MBSimpleRFC822AddressToStringTransformer : NSValueTransformer

@end
