//
//  MBEncodedStringHexOctetTransformer.h
//  MailBoxes
//
//  Created by Taun Chapman on 02/11/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#define VTMBEncodedStringHexOctetTransformer @"MBEncodedStringHexOctetTransformer"

/*!
 Takes a MBEncodedString with hex octet encoding of the form "=XX" and returns an encoded string
 with the "=XX" replaced by the character represented by the "XX" hex encoding of the character set.
 
 @return a decoded MBEncodedString
 */
@interface MBEncodedStringHexOctetTransformer : NSValueTransformer

/*!
 Returns the result of transforming an ascii string with hex encoding to the full charset.
 
 @param anMBencodedString a MBencodedString
 
 @return a decoded MBEncodedString
 */
- (id)transformedValue:(id)anMBencodedString;

@end
