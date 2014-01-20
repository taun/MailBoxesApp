//
//  MBMIMEQuotedPrintableTranformer.h
//  MailBoxes
//
//  Created by Taun Chapman on 10/15/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#define VTQuotedPrintableToString @"quotedPrintableToString"

/*!
 RFC 2045 Internet Message Bodies
 
 quoted-printable := qp-line *(CRLF qp-line)
 qp-line := *(qp-segment transport-padding CRLF)
                qp-part transport-padding
 qp-part := qp-section
                ; Maximum length of 76 characters
 qp-segment := qp-section *(SPACE / TAB) "="
                ; Maximum length of 76 characters
 qp-section := [*(ptext / SPACE / TAB) ptext]
                ptext := hex-octet / safe-char
 safe-char := <any octet with decimal value of 33 through
                60 inclusive, and 62 through 126>
                ; Characters not listed as "mail-safe" in
                ; RFC 2049 are also not recommended.
 hex-octet := "=" 2(DIGIT / "A" / "B" / "C" / "D" / "E" / "F")
                 ; Octet must be used for characters > 127, =,
                 ; SPACEs or TABs at the ends of lines, and is
                 ; recommended for any character not listed in
                 ; RFC 2049 as "mail-safe".
 transport-padding := *LWSP-char
                 ; Composers MUST NOT generate
                 ; non-zero length transport
                 ; padding, but receivers MUST
                 ; be able to handle padding
                 ; added by message transports.
 
 */
@interface MBMIMEQuotedPrintableTranformer : NSValueTransformer

@end
