//
//  MBMIME2047Formatter.m
//  MailBoxes
//
//  Created by Taun Chapman on 09/16/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBMIME2047Formatter.h"

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;


static NSRegularExpression *regexEncodingFields;
static NSRegularExpression *regexQSpaces;

static NSDictionary *charsetMap;


@implementation MBMIME2047Formatter

+(void)initialize {
    NSError *error=nil;
    regexEncodingFields = [[NSRegularExpression alloc] initWithPattern: @"=\\?([A-Z0-9\\-]+)\\?(?:(?:[bB]\\?([+/0-9A-Za-z]*=*))|(?:[qQ]\\?([a-zA-Z0-9._!=\\-]*)))\\?="
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
    
    charsetMap = [[NSDictionary alloc] initWithObjectsAndKeys: [NSNumber numberWithInt: NSASCIIStringEncoding], @"US-ASCII",
                  [NSNumber numberWithInt: NSUTF8StringEncoding], @"UTF-8",
                  [NSNumber numberWithInt: NSISOLatin1StringEncoding], @"ISO-8859-1",
                  [NSNumber numberWithInt: NSWindowsCP1251StringEncoding], @"KOI8-R",
                  [NSNumber numberWithInt: NSNonLossyASCIIStringEncoding], @"US-ASCII2",
                  nil];
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
                        [decodedMutableString appendString: [NSString stringWithCString: utf8Chars encoding: NSUTF8StringEncoding]];
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
 When implementing a subclass, return the NSString object that textually represents the cell’s object for display and—if editingStringForObjectValue: is unimplemented—for editing. First test the passed-in object to see if it’s of the correct class. If it isn’t, return nil; but if it is of the right class, return a properly formatted and, if necessary, localized string. (See the specification of the NSString class for formatting and localizing details.)
 
 @param anObject The object for which a textual representation is returned.
 @returns An NSString object that textually represents object for display. Returns nil if object is not of the correct class.
 
 */
- (NSString *)stringForObjectValue:(id)anObject {
    
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
            int encoding = [[charsetMap objectForKey: charsetString] intValue];
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
/*
 NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:"/(.?)" options:0 error:NULL];
 
 NSString *answer = [re replaceMatchesInString:"a/b/c"
 replacementStringForResult: ^NSString *(NSTextCheckingResult *result, NSString *inString, NSInteger offset) {
 
 // See Note 1 NSRegularExpression *re = [result regularExpression];
 
 // See Note 2 NSString *s1 = [re replacementStringForResult:result
 inString:inString
 offset:offset
 template:"$1"];
 
 return [@"::" stringByAppendingString:[s1 uppercaseString]];
 }];
 NSLog(""%\"", answer);
 */
/*!
When implementing a subclass, return by reference the object anObject after creating it from string. Return YES if the conversion is successful. If you return NO, also return by indirection (in error) a localized user-presentable NSString object that explains the reason why the conversion failed; the delegate (if any) of the NSControl object managing the cell can then respond to the failure in control:didFailToFormatString:errorDescription:. However, if error is nil, the sender is not interested in the error description, and you should not attempt to assign one.
 
 @param anObject If conversion is successful, upon return contains the object created from string.
 @param string The string to parse.
 @param error If non-nil, if there is a error during the conversion, upon return contains an NSString object that describes the problem.
 @returns YES if the conversion from string to cell content object was successful, otherwise NO.
 */
- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error {
    BOOL result = NO;
    
    
    return result;
}

@end
