//
//  MBMIME2047ValueTransformer.m
//  MailBoxes
//
//  Created by Taun Chapman on 09/16/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBMIME2047ValueTransformer.h"

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;


static NSRegularExpression *regexEncodingFields;
static NSRegularExpression *regexQSpaces;

static NSDictionary *charsetMap;


@implementation MBMIME2047ValueTransformer

+(void)initialize {
    NSError *error=nil;
    regexEncodingFields = [[NSRegularExpression alloc] initWithPattern: @"=\\?([A-Z0-9\\-]+)\\?(?:(?:[bB]\\?([+/0-9A-Za-z]*=*))|(?:[qQ]\\?([a-zA-Z0-9._!=\\-@]*)))\\?="
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
    
    charsetMap = @{@"US-ASCII": @(NSASCIIStringEncoding),
                  @"UTF-8": @(NSUTF8StringEncoding),
                  @"ISO-8859-1": @(NSISOLatin1StringEncoding),
                  @"KOI8-R": @(NSWindowsCP1251StringEncoding),
                  @"US-ASCII2": @(NSNonLossyASCIIStringEncoding)};
}

/*!
 This only gets called if there was an "=" found
 
 Location is the first "X" after the "="
 
 Current location of string should be of form ="XY"
 
 Result
 
 * if XY is valid hex, returns XY as UInt8 with location after "=XY"
 * If X is valid and Y is invalid, returns X as UInt8 and location at Y
 * If X and Y are invalid, return 0 and location still at X
 
 @param hexedStringScanner NSScanner
 */
-(UInt8) scanHexFrom: (NSScanner*) hexedStringScanner {
    UInt8 hexCode = 0;
    
    if (isxdigit([hexedStringScanner.string characterAtIndex: hexedStringScanner.scanLocation])
        && isxdigit([hexedStringScanner.string characterAtIndex: hexedStringScanner.scanLocation+1])) {
        // have to hexadecimal digits
        UInt8 hex16ASCII = [hexedStringScanner.string characterAtIndex: hexedStringScanner.scanLocation];
        [hexedStringScanner setScanLocation: ++(hexedStringScanner.scanLocation)];
        UInt8 hex16 = isdigit(hex16ASCII) ? (hex16ASCII - '0') : (hex16ASCII - 55);
        if (hex16 > 15) hex16 -= 32;  // lowercase a-f
        
        UInt8 hex1ASCII = [hexedStringScanner.string characterAtIndex: hexedStringScanner.scanLocation];
        [hexedStringScanner setScanLocation: ++(hexedStringScanner.scanLocation)];
        UInt8 hex1 = isdigit(hex1ASCII) ? (hex1ASCII - '0') : (hex1ASCII - 55);
        if (hex1 > 15) hex1 -= 32;  // lowercase a-f
        
        hexCode = (hex16 << 4) + hex1;
    } else if (isxdigit([hexedStringScanner.string characterAtIndex: hexedStringScanner.scanLocation])
               && !isxdigit([hexedStringScanner.string characterAtIndex: hexedStringScanner.scanLocation+1])) {
        // only one valid hex digit
        UInt8 hex16ASCII = [hexedStringScanner.string characterAtIndex: hexedStringScanner.scanLocation];
        [hexedStringScanner setScanLocation: ++(hexedStringScanner.scanLocation)];
        UInt8 hex16 = isdigit(hex16ASCII) ? (hex16ASCII - '0') : (hex16ASCII - 55);
        if (hex16 > 15) hex16 -= 32;  // lowercase a-f
        
        hexCode = hex16;
    }
    
    return hexCode;
}

-(NSString*) replaceQEncodedHexAndSpaceIn: (NSString*) hexedString encoding: (int) encodingCharset {
    // Change to use NSScanner
    
    // define regex above
    // find matches here
    // create empty new mutable string
    // replace matches with dehexed or spaced and append to new string
    // append intermediate range to string
    // return new string
    NSMutableString* decodedMutableString = [[NSMutableString alloc] initWithCapacity: hexedString.length];
    
    //NSCharacterSet *replaceableCharacters = [NSCharacterSet characterSetWithCharactersInString:@"=_"];
    NSScanner* scanner = [NSScanner scannerWithString: hexedString];
    
    NSString* currentCharacter;
    
    while (![scanner isAtEnd]) {
        currentCharacter = [scanner.string substringWithRange: NSMakeRange(scanner.scanLocation, 1)];
        if ([currentCharacter isEqualToString: @"="] || [currentCharacter isEqualToString: @"_"]) {
            if ([currentCharacter isEqualToString: @"_" ]) {
                // found underscore
                [decodedMutableString appendString: @" "];
                [scanner setScanLocation: ++(scanner.scanLocation)];
            } else if ([currentCharacter isEqualToString: @"=" ]) {
                // found "=" and need to get hex value
                [scanner setScanLocation: ++(scanner.scanLocation)]; // skip "="
                
                // Need to manually get next two characters to convert to hex.
                UInt8 hexCode = [self scanHexFrom: scanner];
                
                if (hexCode!=0) {
                    // valid hex code found
                    char utf8Chars[5];
                    NSUInteger unicodeIndex = 0;
                    utf8Chars[unicodeIndex] = hexCode;
                    if ((encodingCharset == NSUTF8StringEncoding) && (hexCode > 0x7f)) {
                        // Need to handle 2 to 4 encoded bytes
                        // decode byte count
                        // RFC 3269 UTF-8 definition
                        // Char. number range  |        UTF-8 octet sequence
                        // (hexadecimal)    |              (binary)
                        // --------------------+---------------------------------------------
                        // 0000 0000-0000 007F | 0xxxxxxx
                        // 0000 0080-0000 07FF | 110xxxxx 10xxxxxx
                        // 0000 0800-0000 FFFF | 1110xxxx 10xxxxxx 10xxxxxx
                        // 0001 0000-0010 FFFF | 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
                        
                        // 2bytes 110xxxxx = C0, 111xxxxx = E0, 00011111 = 1F
                        // 3bytes 1110xxxx = E0, 1111xxxx = F0, 00001111 = 0F, 00111111 = 3F, 10000000 = 0x80
                        // 4bytes 11110xxx = F0, 11111xxx = F8, 00000111 = 07, 00111111 = 3F, 00111111 = 3F
                        
                        if ((hexCode & 0xE0) == 0xC0) {
                            // 2 bytes
                            currentCharacter = [scanner.string substringWithRange: NSMakeRange(scanner.scanLocation, 1)];
                            if ([currentCharacter isEqualToString: @"="]) {
                                // get second byte
                                [scanner setScanLocation: ++(scanner.scanLocation)]; // skip "="
                                hexCode = [self scanHexFrom: scanner];
                                if ((hexCode & 0xC0) == 0x80) {
                                    // next byte is of correct 10xxxxxx form
                                    utf8Chars[++unicodeIndex] = hexCode;
                                }
                            }
                        } else if ((hexCode & 0xF0) == 0xE0) {
                            // 3 bytes
                            currentCharacter = [scanner.string substringWithRange: NSMakeRange(scanner.scanLocation, 1)];
                            if ([currentCharacter isEqualToString: @"="]) {
                                // get second byte
                                [scanner setScanLocation: ++(scanner.scanLocation)]; // skip "="
                                hexCode = [self scanHexFrom: scanner];
                                if ((hexCode & 0xC0) == 0x80) {
                                    // next byte is of correct 10xxxxxx form
                                    utf8Chars[++unicodeIndex] = hexCode;
                                    currentCharacter = [scanner.string substringWithRange: NSMakeRange(scanner.scanLocation, 1)];
                                    if ([currentCharacter isEqualToString: @"="]) {
                                        // get second byte
                                        [scanner setScanLocation: ++(scanner.scanLocation)]; // skip "="
                                        hexCode = [self scanHexFrom: scanner];
                                        if ((hexCode & 0xC0) == 0x80) {
                                            // next byte is of correct 10xxxxxx form
                                            utf8Chars[++unicodeIndex] = hexCode;
                                        }
                                    }
                                }
                            }
                        } else if ((hexCode & 0xF8) == 0xF0) {
                            // 4 bytes
                            currentCharacter = [scanner.string substringWithRange: NSMakeRange(scanner.scanLocation, 1)];
                            if ([currentCharacter isEqualToString: @"="]) {
                                // get second byte
                                [scanner setScanLocation: ++(scanner.scanLocation)]; // skip "="
                                hexCode = [self scanHexFrom: scanner];
                                if ((hexCode & 0xC0) == 0x80) {
                                    // next byte is of correct 10xxxxxx form
                                    utf8Chars[++unicodeIndex] = hexCode;
                                    currentCharacter = [scanner.string substringWithRange: NSMakeRange(scanner.scanLocation, 1)];
                                    if ([currentCharacter isEqualToString: @"="]) {
                                        // get second byte
                                        [scanner setScanLocation: ++(scanner.scanLocation)]; // skip "="
                                        hexCode = [self scanHexFrom: scanner];
                                        if ((hexCode & 0xC0) == 0x80) {
                                            // next byte is of correct 10xxxxxx form
                                            utf8Chars[++unicodeIndex] = hexCode;
                                            currentCharacter = [scanner.string substringWithRange: NSMakeRange(scanner.scanLocation, 1)];
                                            if ([currentCharacter isEqualToString: @"="]) {
                                                // get second byte
                                                [scanner setScanLocation: ++(scanner.scanLocation)]; // skip "="
                                                hexCode = [self scanHexFrom: scanner];
                                                if ((hexCode & 0xC0) == 0x80) {
                                                    // next byte is of correct 10xxxxxx form
                                                    utf8Chars[++unicodeIndex] = hexCode;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            // bad value skip
                        }
                        utf8Chars[++unicodeIndex] = 0; // null terminate
                        [decodedMutableString appendString: @(utf8Chars)];
                    } else {
                        // not UTF-8 > 7F
                        utf8Chars[++unicodeIndex] = 0; // null terminate
                        [decodedMutableString appendString: [NSString stringWithCString: utf8Chars encoding: encodingCharset]];
                    }
                } else {
                    // no valid code found
                    // was not two hexadecimal digits
                    [decodedMutableString appendFormat:@"=%c", [scanner.string characterAtIndex: scanner.scanLocation]];
                    [scanner setScanLocation: ++(scanner.scanLocation)]; // skip "="
                }
            }
        } else {
            [decodedMutableString appendString: currentCharacter];
            [scanner setScanLocation: ++(scanner.scanLocation)];
        }
        
    }
    
    
    
    
    return [decodedMutableString copy];
}

-(NSString*) replaceBEncodedString: (NSString*) base64String encoding: (int) encodingCharset {

    NSData* decodedData = [[NSData alloc] initWithBase64Encoding: base64String];
    NSString* decodedString = [[NSString alloc] initWithData: decodedData encoding: encodingCharset];
    
    return decodedString;
}
/*!
 Returns the result of transforming a given value.
 
 A subclass should override this method to transform and return an object based on value.
 
 @param anObject The value to transform. This object should be an string containing RFC 2047 MIME Encoded words. If there are no encoded words, it just returns a new string with the same content.
 @returns The result of transforming value. Encoded words are replaced with their UTF8 encoding.
 
 */
- (id)transformedValue:(id)anObject {
    
    NSArray* matches;
    
    if ([anObject isKindOfClass:[NSString class]]) {
        NSInteger length = [(NSString*)anObject length];
        matches = [regexEncodingFields matchesInString: anObject options: 0 range: NSMakeRange(0, length)];
    }
    
    NSInteger charsetRangeIndex = 1;
    NSInteger bCodeRangeIndex = 2;
    NSInteger qCodeRangeIndex = 3;
    // rangge length 0 means not found
    
    NSString* charsetString;
    NSMutableString* decodedString = [NSMutableString new];
    
    if (matches.count==0) {
        decodedString = anObject;
    } else {
        
        NSRange lastCaptureRange = NSMakeRange(0, 0);
        NSRange currentCaptureRange;
        
        for (NSTextCheckingResult* tcr in matches) {
            
            // Append the ascii string before the capture encoded word.
            // 0 aaaaaaaaa =?lastCaptureRange?= bbbbbbbbbbb =?currentCaptureRange?= cccccccc
            currentCaptureRange = (NSRange)[tcr rangeAtIndex:0];
            NSUInteger prefixLocation = lastCaptureRange.location + lastCaptureRange.length;
            NSUInteger prefixLength = currentCaptureRange.location - prefixLocation;
            NSRange prefixRange = NSMakeRange(prefixLocation, prefixLength);
            
            NSString* intraCaptureString = [anObject substringWithRange: prefixRange];
            NSString* noWhitespaceString = [intraCaptureString stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
            
            // if the intraCapture text is whitespace, skip, do not append.
            [decodedString appendString: noWhitespaceString];
            
            lastCaptureRange = (NSRange)[tcr rangeAtIndex:0];
            
            if ([tcr rangeAtIndex: charsetRangeIndex].length != 0) {
                charsetString = [[(NSString*)anObject substringWithRange: [tcr rangeAtIndex: charsetRangeIndex]] uppercaseString];
            }
            
            NSRange encodedRange;
            int encoding = [charsetMap[charsetString] intValue];
            if ([tcr rangeAtIndex: bCodeRangeIndex].length != 0) {
                // b encoded
                encodedRange = [tcr rangeAtIndex: bCodeRangeIndex];
                if (encodedRange.length !=0) {
                    //                    NSString* encodedString = [(NSString*)anObject substringWithRange: encodedRange];
                    //                    const char* encodedCString
                    //                    [decodedString appendString: encodedString];
                    NSString* encodedString = [(NSString*)anObject substringWithRange: encodedRange];
                    NSString* fullyDecodedString = [self replaceBEncodedString: encodedString encoding: encoding];
                    [decodedString appendString: fullyDecodedString];
                }
            } else if ([tcr rangeAtIndex: qCodeRangeIndex].length != 0) {
                // q encoded
                encodedRange = [tcr rangeAtIndex: qCodeRangeIndex];
                if (encodedRange.length !=0) {
                    NSString* encodedString = [(NSString*)anObject substringWithRange: encodedRange];
                    const char* encodedCString = [encodedString cStringUsingEncoding: NSASCIIStringEncoding];
                    NSString* decodedCString = [NSString stringWithCString: encodedCString encoding: encoding];
                    // search and replace "=XX" and "_"
                    NSString* fullyDecodedString = [self replaceQEncodedHexAndSpaceIn: decodedCString encoding: encoding];
                    [decodedString appendString: fullyDecodedString];
                }
            } else {
                // unknown encoding?? assert?
            }
        }
        // append remaining suffix ascii string if it exists
        NSUInteger suffixLocation = lastCaptureRange.location + lastCaptureRange.length;
        NSUInteger suffixLength = [(NSString*)anObject length] - suffixLocation;
        NSRange suffixRange = NSMakeRange(suffixLocation, suffixLength);
        [decodedString appendString: [[anObject substringWithRange:suffixRange] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]]];
    }
    
    return decodedString;
}

@end
