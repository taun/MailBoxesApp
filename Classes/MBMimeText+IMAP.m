//
//  MBMimeText+IMAP.m
//  MailBoxes
//
//  Created by Taun Chapman on 10/08/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//


#import "MBMimeText+IMAP.h"
#import "NSObject+MBShorthand.h"


@implementation MBMimeText (IMAP)

-(void) decoder {
    NSData* decoded;
    if ([self.data.encoded isNonNilString]) {
        NSString* stringToDecode = self.data.encoded;
        
        NSNumber* nsEncodingNumber = [[MBMIMECharsetTransformer new] transformedValue: self.charset];
        int nsEncodingInt = NSASCIIStringEncoding; // default
        
        if (nsEncodingNumber != nil) {
            // default
            nsEncodingInt = [nsEncodingNumber intValue];
        }
        // does not work for HTML! Check charset and encoding
        // use charset mapping from ? encoded-word transform
        if ([[self.encoding uppercaseString] isEqualToString: @"QUOTED-PRINTABLE"]) {
            //
            stringToDecode = [[MBMIMEQuotedPrintableTranformer new] transformedValue: self.data.encoded];
        }
        
        decoded = [stringToDecode dataUsingEncoding: nsEncodingInt];
        
        NSAssert((decoded != nil) && (decoded.length>4), @"decoded is an empty string: %@, data=%@", decoded, self.data);
        
        if (decoded) {
            self.data.decoded = decoded;
            self.data.isDecoded = @YES;
        }
    }
}

/*!
 Need to decode data based on the subtype and encoding.
 Subtypes can be
    PLAIN
    ENRICHED
    HTML
 
 Encoding may be
    quoted-printable
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
