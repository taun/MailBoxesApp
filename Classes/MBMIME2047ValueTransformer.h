//
//  MBMIME2047ValueTransformer.h
//  MailBoxes
//
//  Created by Taun Chapman on 09/16/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBMIMECharsetTransformer.h"

#define VTRFC2047EncodedToString @"rfc2047EncodedToString"

/*!
 Transforms string with RFC 2047 encoded words to UTF8 string.
 
 See RFC2047 for more details on the encoding.
 
 Use transformedValue: to transform an encoded string to decoded.
 */
@interface MBMIME2047ValueTransformer : NSValueTransformer

+(NSDictionary*) CharsetMap;

@end
