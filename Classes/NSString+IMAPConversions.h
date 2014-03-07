//
//  NSString+IMAPConversions.h
//  MailBoxes
//
//  Created by Taun Chapman on 11/1/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SimpleRFC822Address;

@interface NSString (IMAPConversions)


/*!
 RFC822 Header Format = Tue, 12 Feb 2008 09:36:17 -0500
 INTERNALDATE Format =  "26-Jul-2011 07:48:41 -0400"
 */
-(NSDate*) mdcDateFromRFC3501Format;

/*!
 RFC822 Header Format = Tue, 12 Feb 2008 09:36:17 -0500
 RFC822 Header Format = Tue, 12 Feb 2008 09:36:17 "GMT"  obsolete
 */
-(NSDate*) mdcDateFromRFC822Format;

-(NSString*) mdcStringAsSelectorSafeCamelCase;

-(NSString*) mdcStringFromBase64WithCharset: (int) encodingCharset;


/*!
 Transforms string with RFC 2047 encoded words to UTF8 string.
 See RFC2047 for more details on the encoding.
 Use transformedValue: to transform an encoded string to decoded.
 
 Handles single line Q and B encoding in ascii string.
 
 @anAsciiEncodedString a one line string with potential Q or B encoding.
 
 @return a decoded utf8 NSString
 */
-(NSString*) mdcStringByDecodingRFC2047;

-(NSString*) mdcStringDeQuotedPrintableFromCharset: (int) encodingCharset;


/*!
 A string with hex octet encoding of the form "=XX" and returns a string
 with the "=XX" replaced by the character represented by the "XX" hex encoding of the character set.
 
 @return a decoded NSString
 */
-(NSString*) mdcStringFromQEncodedAsciiHexInCharset: (int) encodingCharset;

-(SimpleRFC822Address*) mdcSimpleRFC822Address;

/*!
 Transforms from MIME strings representing a character set to an NSNumber representing an NS domain character set.
 
 Will handle upper or lower case MIME strings.
 
 @returns nil if charset is not found.
 */
-(id) mdcNumberFromIANACharset;

@end
