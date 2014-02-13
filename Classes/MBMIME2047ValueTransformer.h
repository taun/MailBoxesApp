//
//  MBMIME2047ValueTransformer.h
//  MailBoxes
//
//  Created by Taun Chapman on 09/16/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBMIMECharsetTransformer.h"

#define VTMBMIME2047ValueTransformer @"MBMIME2047ValueTransformer"

/*!
 Transforms string with RFC 2047 encoded words to UTF8 string.
  See RFC2047 for more details on the encoding.
  Use transformedValue: to transform an encoded string to decoded.
 
 Handles single line Q and B encoding in ascii string.
 
 @anAsciiEncodedString a one line string with potential Q or B encoding.
 
 @return a decoded utf8 NSString
 */
@interface MBMIME2047ValueTransformer : NSValueTransformer

/*!
 Returns the result of transforming anAsciiEncodedString.
 
 A subclass should override this method to transform and return an object based on value.
 
 @param anAsciiEncodedString The value to transform. This object should be an string containing RFC 2047 MIME Encoded words. If there are no encoded words, it just returns a new string with the same content.
 
 @returns The result of transforming value. Encoded words are replaced with their UTF8 encoding.
 
 */
- (id)transformedValue:(id)anAsciiEncodedString;

@end
