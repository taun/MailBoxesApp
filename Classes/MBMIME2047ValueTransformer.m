//
//  MBMIME2047ValueTransformer.m
//  MailBoxes
//
//  Created by Taun Chapman on 09/16/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBMIME2047ValueTransformer.h"
#import "MBEncodedStringHexOctetTransformer.h"
#import "MBEncodedString.h"
#import "MBMIMECharsetTransformer.h"


static NSRegularExpression *regexEncodingFields;
static NSRegularExpression *regexQSpaces;


@implementation MBMIME2047ValueTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+(void)initialize {
    NSError *error=nil;
    regexEncodingFields = [[NSRegularExpression alloc] initWithPattern: @"=\\?([A-Z0-9\\-]+)\\?(?:(?:[bB]\\?([+/0-9A-Za-z]*=*))|(?:[qQ]\\?([a-zA-Z0-9.,_!=/\\*\\+\\-@]*)))\\?="
                                                               options: NSRegularExpressionCaseInsensitive
                                                                 error: &error];
    if (error) {
        NSLog(@"Encoding Fields Error: %@", error);
    }
    
    regexQSpaces = [[NSRegularExpression alloc] initWithPattern: @"=([0-9a-zA-Z][0-9a-zA-Z]?)|(_)"
                                                        options: NSRegularExpressionCaseInsensitive
                                                          error: &error];
    if (error) {
        NSLog(@"Q Spaces Error: %@", error);
    }
    
}

-(NSString*) replaceBEncodedString: (NSString*) base64String encoding: (int) encodingCharset {

    NSData* decodedData = [[NSData alloc] initWithBase64Encoding: base64String];
    NSString* decodedString = [[NSString alloc] initWithData: decodedData encoding: encodingCharset];
    
    return decodedString;
}

- (id)transformedValue:(id)anAsciiEncodedString {
    
    NSString* returnString;
    
    NSValueTransformer* hexTransformer = [NSValueTransformer valueTransformerForName: VTMBEncodedStringHexOctetTransformer];
    NSValueTransformer* charsetTransformer = [NSValueTransformer valueTransformerForName: VTMBMIMECharsetTransformer];
    
    NSArray* matches;
    
    if ([anAsciiEncodedString isKindOfClass:[NSString class]]) {
        NSInteger length = [(NSString*)anAsciiEncodedString length];
        matches = [regexEncodingFields matchesInString: anAsciiEncodedString options: 0 range: NSMakeRange(0, length)];
    }
    
    NSInteger charsetRangeIndex = 1;
    NSInteger bCodeRangeIndex = 2;
    NSInteger qCodeRangeIndex = 3;
    // rangge length 0 means not found
    
    
    if (matches.count==0) {
        returnString = anAsciiEncodedString;
    } else {
        
        NSString* charsetString;
        NSMutableString* decodedString = [NSMutableString new];

        NSRange lastCaptureRange = NSMakeRange(0, 0);
        NSRange currentCaptureRange;
        
        for (NSTextCheckingResult* tcr in matches) {
            
            // Append the ascii string before the capture encoded word.
            // 0 aaaaaaaaa =?lastCaptureRange?= bbbbbbbbbbb =?currentCaptureRange?= cccccccc
            currentCaptureRange = (NSRange)[tcr rangeAtIndex:0];
            NSUInteger prefixLocation = lastCaptureRange.location + lastCaptureRange.length;
            NSUInteger prefixLength = currentCaptureRange.location - prefixLocation;
            NSRange prefixRange = NSMakeRange(prefixLocation, prefixLength);
            
            NSString* intraCaptureString = [anAsciiEncodedString substringWithRange: prefixRange];
            NSString* noWhitespaceString = [intraCaptureString stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
            
            // if the intraCapture text is whitespace, skip, do not append.
            [decodedString appendString: noWhitespaceString];
            
            lastCaptureRange = (NSRange)[tcr rangeAtIndex:0];
            
            if ([tcr rangeAtIndex: charsetRangeIndex].length != 0) {
                charsetString = [[(NSString*)anAsciiEncodedString substringWithRange: [tcr rangeAtIndex: charsetRangeIndex]] uppercaseString];
            }
            
            NSRange encodedRange;
            NSNumber* encodingNumber = [charsetTransformer transformedValue: charsetString];
            
#pragma message "Need to handle charset not found"
            int encoding = [encodingNumber intValue]; //TODO: handle charset not found.
            if ([tcr rangeAtIndex: bCodeRangeIndex].length != 0) {
                // b encoded
                encodedRange = [tcr rangeAtIndex: bCodeRangeIndex];
                if (encodedRange.length !=0) {
                    //                    NSString* encodedString = [(NSString*)anObject substringWithRange: encodedRange];
                    //                    const char* encodedCString
                    //                    [decodedString appendString: encodedString];
                    NSString* encodedString = [(NSString*)anAsciiEncodedString substringWithRange: encodedRange];
                    NSString* fullyDecodedString = [self replaceBEncodedString: encodedString encoding: encoding];
                    [decodedString appendString: fullyDecodedString];
                }
            } else if ([tcr rangeAtIndex: qCodeRangeIndex].length != 0) {
                // q encoded
                encodedRange = [tcr rangeAtIndex: qCodeRangeIndex];
                if (encodedRange.length !=0) {
                    NSString* encodedString = [(NSString*)anAsciiEncodedString substringWithRange: encodedRange];
                    const char* encodedCString = [encodedString cStringUsingEncoding: NSASCIIStringEncoding];
                    MBEncodedString* decodedCString = [MBEncodedString encodedString: [NSString stringWithCString: encodedCString encoding: encoding] encoding: encoding];
                    // search and replace "=XX" and "_"
                    MBEncodedString* deHexedEncoded = [hexTransformer transformedValue: decodedCString];
                    [decodedString appendString: deHexedEncoded.string];
                }
            } else {
                // unknown encoding?? assert?
            }
        }
        // append remaining suffix ascii string if it exists
        NSUInteger suffixLocation = lastCaptureRange.location + lastCaptureRange.length;
        NSUInteger suffixLength = [(NSString*)anAsciiEncodedString length] - suffixLocation;
        NSRange suffixRange = NSMakeRange(suffixLocation, suffixLength);
        [decodedString appendString: [[anAsciiEncodedString substringWithRange:suffixRange] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]]];
        
        returnString = [decodedString copy];
    }
    
    return returnString;
}

#pragma message "TODO: reverseTransform"

@end
