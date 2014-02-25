//
//  MBMimeText+IMAP.m
//  MailBoxes
//
//  Created by Taun Chapman on 10/08/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//


#import "MBMimeText+IMAP.h"
#import "NSObject+MBShorthand.h"
#import "MBEncodedString.h"


@implementation MBMimeText (IMAP)

#pragma message "ToDo: implement registry/methods for decodings and use to decode in first part of decoder for all MBMime types"
// implement methods in MBMime using similar pattern to IMAPClient
// MBMime methods call transformers or just call transformers here?
// Need to map transformer to encoding. Can be done here or as MBMime method called. "decodeBASE64", "decode7BIT"
// mechanism := "7bit" / "8bit" / "binary" / "quoted-printable" / "base64"
-(void) decoder {
    NSValueTransformer* charsetTransformer = [NSValueTransformer valueTransformerForName: VTMBMIMECharsetTransformer];

    MBEncodedString* stringToDecode;
    NSData* decoded;
    

    if ([self.data.encoded isNonNilString]) {

        // Convert IANA charset to NSStringEncoding, example "utf-8" = 4
        NSNumber* nsEncodingNumber = [charsetTransformer transformedValue: self.charset];
        
        int nsEncodingInt;
        
        if (nsEncodingNumber != nil) {
            nsEncodingInt = [nsEncodingNumber intValue];
        } else {
            nsEncodingInt = NSASCIIStringEncoding; // default
        }
        
        // base64?
        if ([[self.encoding uppercaseString] isEqualToString: @"BASE64"]) {
            // decode from base64 first
            decoded = [[NSData alloc] initWithBase64EncodedString: self.data.encoded options: NSDataBase64DecodingIgnoreUnknownCharacters];
            if (nsEncodingInt != NSASCIIStringEncoding && nsEncodingInt != NSUTF8StringEncoding) {
                // convert to utf-8
                NSString* utf8String = [[NSString alloc] initWithData: decoded encoding: nsEncodingInt];
                NSData* utf8Data = [utf8String dataUsingEncoding: NSUTF8StringEncoding];
                decoded = utf8Data;
            }
            
#pragma message "ToDo: TEST, if base64 and charset is not utf-8, need to convert from charset to utf-8 as part of decoding."
            
        } else {
            stringToDecode = [MBEncodedString encodedString: self.data.encoded encoding: nsEncodingInt];
            
            if ([[self.encoding uppercaseString] isEqualToString: @"QUOTED-PRINTABLE"]) {
                //
                NSValueTransformer* quotedPrintableTransformer = [NSValueTransformer valueTransformerForName: VTMBMIMEQuotedPrintableTranformer];
                stringToDecode = [quotedPrintableTransformer transformedValue: stringToDecode];
                stringToDecode.encoding = NSUTF8StringEncoding;
            }
            
            decoded = [stringToDecode asData];
        }
        
        
        NSAssert((decoded != nil) && (decoded.length>4), @"decoded is an empty string: %@, data=%@", decoded, self.data);
        
        if (decoded) {
            self.data.decoded = decoded;
            self.data.isDecoded = @YES;
        }
    }
}

/*!
 This method is being deprecated.
 
 Need to decode data based on the subtype and encoding.
 Subtypes can be
    PLAIN
    ENRICHED
    HTML
 
 Encoding may be
    quoted-printable, BASE64
 
 @param options NSDictionary of NSDocumentTypeOption same as NSAttributedString initWithData:options:documentAttributes:error:
 
 @param attributes An in-out dictionary containing document-level attributes described in “Document Attributes”. May be NULL, in which case no document attributes are returned.
 */
-(NSAttributedString*) asAttributedStringWithOptions:(NSDictionary *)options attributes: (NSDictionary*) attributes {
    NSAttributedString* returnString;
    
    if ([self.subtype isEqualToString: @"PLAIN"]) {
        returnString = [self plainAsAttributedStringWithOptions:options attributes:attributes];
        
    } else  if ([self.subtype isEqualToString: @"ENRICHED"]) {
        returnString = [self enrichedAsAttributedStringWithOptions:options attributes:attributes];
        
    } else if ([self.subtype isEqualToString: @"HTML"]) {
        returnString = [self htmlAsAttributedStringWithOptions:options attributes:attributes];
    }
    
    return returnString;
}

-(NSAttributedString*) plainAsAttributedStringWithOptions:(NSDictionary *)options attributes: (NSDictionary*) attributes {
    NSData* nsData = [self getDecodedData];
    
    NSAttributedString* returnString = [[NSAttributedString alloc] initWithData: nsData options: nil documentAttributes: &attributes error: nil];
    
    return returnString;
}
-(NSAttributedString*) htmlAsAttributedStringWithOptions:(NSDictionary *)options attributes: (NSDictionary*) attributes {
    NSData* nsData = [self getDecodedData];
    
    NSAttributedString* returnString = [[NSAttributedString alloc] initWithHTML: nsData documentAttributes: &attributes];
    
    return returnString;
}
-(NSAttributedString*) enrichedAsAttributedStringWithOptions:(NSDictionary *)options attributes: (NSDictionary*) attributes {
    NSData* nsData = [self getDecodedData];
    
    NSAttributedString* returnString = [[NSAttributedString alloc] initWithData: nsData options: nil documentAttributes: &attributes error: nil];
    
    return returnString;
}

@end
