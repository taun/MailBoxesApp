//
//  MBEncodedStringHexOctetTransformer.m
//  MailBoxes
//
//  Created by Taun Chapman on 02/11/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBEncodedStringHexOctetTransformer.h"
#import "MBEncodedString.h"

@implementation MBEncodedStringHexOctetTransformer

+ (Class)transformedValueClass {
    return [MBEncodedString class];
}

- (id)transformedValue:(id)anMBencodedString {
    MBEncodedString* dehexedString;
    if ([anMBencodedString isKindOfClass:[MBEncodedString class]]) {
        dehexedString = [self replaceQEncodedHexAndSpaceIn: (MBEncodedString*)anMBencodedString];
    }
    return dehexedString;
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

-(MBEncodedString*) replaceQEncodedHexAndSpaceIn: (MBEncodedString*) encodedHexedString {
    // Change to use NSScanner
    
    // define regex above
    // find matches here
    // create empty new mutable string
    // replace matches with dehexed or spaced and append to new string
    // append intermediate range to string
    // return new string
    NSMutableString* decodedMutableString = [[NSMutableString alloc] initWithCapacity: encodedHexedString.string.length];
    
    //NSCharacterSet *replaceableCharacters = [NSCharacterSet characterSetWithCharactersInString:@"=_"];
    NSScanner* scanner = [NSScanner scannerWithString: encodedHexedString.string];
    
    NSString* currentCharacter;
    
    while (![scanner isAtEnd]) {
        currentCharacter = [scanner.string substringWithRange: NSMakeRange(scanner.scanLocation, 1)];
        if ([currentCharacter isEqualToString: @"="] || [currentCharacter isEqualToString: @"_"]) {
            if ([currentCharacter isEqualToString: @"_" ]) {
                // found underscore
                [decodedMutableString appendString: @" "];
                [scanner setScanLocation: ++(scanner.scanLocation)];
            } else if ([currentCharacter isEqualToString: @"=" ] && (scanner.string.length - scanner.scanLocation > 2)) {
                // found "=" and need to get next 2 char hex value
                [scanner setScanLocation: ++(scanner.scanLocation)]; // skip "="
                
                // Need to manually get next two characters to convert to hex.
                UInt8 hexCode = [self scanHexFrom: scanner];
                
                if (hexCode!=0) {
                    // valid hex code found
                    char utf8Chars[5];
                    NSUInteger unicodeIndex = 0;
                    utf8Chars[unicodeIndex] = hexCode;
                    if ((encodedHexedString.encoding == NSUTF8StringEncoding) && (hexCode > 0x7f) && (scanner.string.length - scanner.scanLocation > 2)) {
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
                            // 2 bytes, additional 3 chars
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
                        } else if (((hexCode & 0xF0) == 0xE0) && (scanner.string.length - scanner.scanLocation > 5)) {
                            // 3 bytes, additional 6 chars
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
                        } else if (((hexCode & 0xF8) == 0xF0) && (scanner.string.length - scanner.scanLocation > 8)) {
                            // 4 bytes, additional 9 chars
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
                        NSString* newString = @(utf8Chars);
                        if (newString) {
                            [decodedMutableString appendString: newString];
                        }
                    } else {
                        // not UTF-8 > 7F
                        utf8Chars[++unicodeIndex] = 0; // null terminate
                        NSString* newString = [NSString stringWithCString: utf8Chars encoding: encodedHexedString.encoding];
                        if (newString) {
                            [decodedMutableString appendString: newString];
                        }
                    }
                } else {
                    // no valid code found
                    // was not two hexadecimal digits
                    [decodedMutableString appendFormat:@"=%c", [scanner.string characterAtIndex: scanner.scanLocation]];
                    [scanner setScanLocation: ++(scanner.scanLocation)]; // skip "="
                }
            }
        } else {
            if (currentCharacter) {
                [decodedMutableString appendString: currentCharacter];
            }
            [scanner setScanLocation: ++(scanner.scanLocation)];
        }
        
    }
    
    
    
    
    return [MBEncodedString encodedString: [decodedMutableString copy] encoding: encodedHexedString.encoding];
}


@end
