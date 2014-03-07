//
//  NSString+IMAPConversions.m
//  MailBoxes
//
//  Created by Taun Chapman on 11/1/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import "NSString+IMAPConversions.h"
#import "NSScanner+IMAPConversions.h"

#import "NSObject+MBShorthand.h"
#import "SimpleRFC822Address.h"

#include <time.h>
#include <xlocale.h>

@implementation NSString (IMAPConversions)

-(NSDate *) mdcDateFromRFC3501Format {
    NSDate *            internalDate = nil;
    
    struct tm  sometime;
    const char *rfc3501DateFormat = "%e-%b-%Y %H:%M:%S %z";
    char* transformResult = strptime_l([self cStringUsingEncoding: NSUTF8StringEncoding], rfc3501DateFormat, &sometime, NULL);
    
    if (transformResult != NULL) {
        internalDate = [NSDate dateWithTimeIntervalSince1970: mktime(&sometime)];
    }
    return internalDate;
}
-(NSDate *) mdcDateFromRFC822Format {
    NSDate *internalDate = nil;
    static NSDateFormatter *sRFC2822DateFormatter = nil;
    //NSDateFormatter *dateFormatter;
    NSLocale *enUSPOSIXLocale;
    
    static NSRegularExpression *sLocateRFC2822Date = nil;
    NSError *regexError;
    
    if (sRFC2822DateFormatter==nil) {
        sRFC2822DateFormatter = [[NSDateFormatter alloc] init];
        enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        
        [sRFC2822DateFormatter setLocale:enUSPOSIXLocale];
        [sRFC2822DateFormatter setDateFormat:@"dd MMM yyyy HH:mm:ss"];
        
        sLocateRFC2822Date = [[NSRegularExpression alloc] initWithPattern: @"(\\d{1,2} \\w{3} \\d{4} \\d{2}:\\d{2}:\\d{2})\\s(.\\d{4})|(\\d{1,2} \\w{3} \\d{4} \\d{2}:\\d{2}:\\d{2})\\s?\"?(\\w{3})"
                                                                  options: 0 
                                                                    error: &regexError];
    }
    if (self) {
        NSTextCheckingResult *dateFound = [sLocateRFC2822Date firstMatchInString: self 
                                                                         options: 0 
                                                                           range:NSMakeRange(0, [self length])];
        
        NSString *timeZoneString = nil;
        NSTimeZone *messageTimeZone = nil;
        NSRange dateRange;
        
        if ([dateFound numberOfRanges] >= 5) {
            // should be full plus two capture ranges
            // date should be @ 1
            // timezone should be at 2
            //DDLogVerbose(@"Ranges: %lu\n", [dateFound numberOfRanges]);
            //NSRange range0 = [dateFound rangeAtIndex: 0]; // full range of found expression
            NSRange range1 = [dateFound rangeAtIndex: 1];
            NSRange range2 = [dateFound rangeAtIndex: 2];
            NSRange range3 = [dateFound rangeAtIndex: 3];
            NSRange range4 = [dateFound rangeAtIndex: 4];
            
            if (range1.length >0 && range2.length > 0) {
                // first type
                timeZoneString = [self substringWithRange: range2];
                NSInteger timeZoneDecimal100Hours = [timeZoneString integerValue];
                messageTimeZone = [NSTimeZone timeZoneForSecondsFromGMT: timeZoneDecimal100Hours*60*60/100];
                dateRange = range1;
                
                //DDLogVerbose(@"%@\n",[stringWithRFC2822Date substringWithRange: [dateFound rangeAtIndex: 1]]);
                //DDLogVerbose(@"%@\n",[stringWithRFC2822Date substringWithRange: [dateFound rangeAtIndex: 2]]);
            } else if (range3.length >0 && range4.length > 0) {
                // 2nd type
                timeZoneString = [self substringWithRange: range4];
                messageTimeZone = [NSTimeZone timeZoneWithAbbreviation: timeZoneString];
                if (messageTimeZone==nil) {
                    // default to GMT
                    messageTimeZone = [NSTimeZone timeZoneForSecondsFromGMT: 0];
                }
                dateRange = range3;
                //DDLogVerbose(@"%@\n",[stringWithRFC2822Date substringWithRange: [dateFound rangeAtIndex: 3]]);
                //DDLogVerbose(@"%@\n",[stringWithRFC2822Date substringWithRange: [dateFound rangeAtIndex: 4]]);
            }
            
            [sRFC2822DateFormatter setTimeZone: messageTimeZone];
            
            [sRFC2822DateFormatter getObjectValue: &internalDate 
                                        forString: self 
                                            range: &dateRange  
                                            error: &regexError];
        }
        
    }
    
    return internalDate;
}

-(NSString *) mdcStringAsSelectorSafeCamelCase {
    // commands like READ-ONLY become ReadOnly
    NSString *normalized = [self capitalizedString];
    normalized = [normalized stringByReplacingOccurrencesOfString: @"-" withString: @""];
    normalized = [normalized stringByReplacingOccurrencesOfString: @"." withString: @""];
    normalized = [normalized stringByReplacingOccurrencesOfString: @"[" withString: @""];
    normalized = [normalized stringByReplacingOccurrencesOfString: @"]" withString: @""];
    return normalized;
}

-(NSString*) mdcStringFromBase64WithCharset: (int) encodingCharset {
    
    NSData* decodedData = [[NSData alloc] initWithBase64Encoding: self];
    NSString* decodedString = [[NSString alloc] initWithData: decodedData encoding: encodingCharset];
    
    return decodedString;
}


-(SimpleRFC822Address*) mdcSimpleRFC822Address {
    SimpleRFC822Address* rfcaddress;

    NSString* addressString = [self stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([addressString isNonNilString]) {
        NSMutableCharacterSet* addressDelimiters = [NSMutableCharacterSet characterSetWithCharactersInString: @"<>"];
        [addressDelimiters formUnionWithCharacterSet: [NSCharacterSet whitespaceCharacterSet]];
        
        NSMutableCharacterSet* nameDelimiters = [NSMutableCharacterSet characterSetWithCharactersInString: @"\""];
        [nameDelimiters formUnionWithCharacterSet: [NSCharacterSet whitespaceCharacterSet]];
        
        // Find space between name and address "first last <mailbox@domain>"
        NSRange lastSpace = [addressString rangeOfString: @" " options: NSBackwardsSearch];
        
        rfcaddress = [SimpleRFC822Address new];
        
        if (lastSpace.location != NSNotFound) {
            
            NSString* potentiallyEncodedWord = [[addressString substringWithRange: NSMakeRange(0, lastSpace.location)]
                                                stringByTrimmingCharactersInSet: nameDelimiters];
            
            NSString* potentiallyDecodedWord = [potentiallyEncodedWord mdcStringByDecodingRFC2047];
            
            rfcaddress.name =  potentiallyDecodedWord;
            
            rfcaddress.email = [[addressString substringWithRange: NSMakeRange(lastSpace.location+1, addressString.length-lastSpace.location-1)]
                                stringByTrimmingCharactersInSet: addressDelimiters];
        } else {
            // only have <mailbox@domain>
            rfcaddress.email = [addressString stringByTrimmingCharactersInSet: addressDelimiters];
        }
        
        if (rfcaddress.email) {
            NSMutableArray* subcomponents = [[rfcaddress.email componentsSeparatedByString: @"@"] mutableCopy];
            if (subcomponents.count > 1) {
                rfcaddress.domain = [subcomponents lastObject];
                [subcomponents removeLastObject];
                rfcaddress.mailbox = [subcomponents componentsJoinedByString: @"@"];
            }
        }
    }
    return rfcaddress;
}

-(NSString*) mdcStringByDecodingRFC2047 {
    NSString* returnString;

    NSError *error=nil;
    NSRegularExpression* regexEncodingFields = [[NSRegularExpression alloc] initWithPattern: @"=\\?([A-Z0-9\\-]+)\\?(?:(?:[bB]\\?([+/0-9A-Za-z]*=*))|(?:[qQ]\\?([a-zA-Z0-9.,_!=/\\*\\+\\-@]*)))\\?="
                                                               options: NSRegularExpressionCaseInsensitive
                                                                 error: &error];
    if (error) {
        NSLog(@"Encoding Fields Error: %@", error);
    }
    
    NSRegularExpression* regexQSpaces = [[NSRegularExpression alloc] initWithPattern: @"=([0-9a-zA-Z][0-9a-zA-Z]?)|(_)"
                                                        options: NSRegularExpressionCaseInsensitive
                                                          error: &error];
    if (error) {
        NSLog(@"Q Spaces Error: %@", error);
    }
    
    NSArray* matches;
    
    matches = [regexEncodingFields matchesInString: self options: 0 range: NSMakeRange(0, self.length)];
    
    NSInteger charsetRangeIndex = 1;
    NSInteger bCodeRangeIndex = 2;
    NSInteger qCodeRangeIndex = 3;
    // rangge length 0 means not found
    
    
    if (matches.count==0) {
        returnString = [self copy];
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
            
            NSString* intraCaptureString = [self substringWithRange: prefixRange];
            NSString* noWhitespaceString = [intraCaptureString stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
            
            // if the intraCapture text is whitespace, skip, do not append.
            [decodedString appendString: noWhitespaceString];
            
            lastCaptureRange = (NSRange)[tcr rangeAtIndex:0];
            
            if ([tcr rangeAtIndex: charsetRangeIndex].length != 0) {
                charsetString = [[self substringWithRange: [tcr rangeAtIndex: charsetRangeIndex]] uppercaseString];
            }
            
            NSRange encodedRange;
            NSNumber* encodingNumber = [charsetString mdcNumberFromIANACharset];
            
#pragma message "Need to handle charset not found"
            int encoding = [encodingNumber intValue]; //TODO: handle charset not found.
            if ([tcr rangeAtIndex: bCodeRangeIndex].length != 0) {
                // b encoded
                encodedRange = [tcr rangeAtIndex: bCodeRangeIndex];
                if (encodedRange.length !=0) {
                    //                    NSString* encodedString = [(NSString*)anObject substringWithRange: encodedRange];
                    //                    const char* encodedCString
                    //                    [decodedString appendString: encodedString];
                    NSString* encodedString = [self substringWithRange: encodedRange];
                    NSString* fullyDecodedString = [encodedString mdcStringFromBase64WithCharset: encoding];
                    [decodedString appendString: fullyDecodedString];
                }
            } else if ([tcr rangeAtIndex: qCodeRangeIndex].length != 0) {
                // q encoded
                encodedRange = [tcr rangeAtIndex: qCodeRangeIndex];
                if (encodedRange.length !=0) {
                    NSString* encodedString = [self substringWithRange: encodedRange];
                    const char* encodedCString = [encodedString cStringUsingEncoding: NSASCIIStringEncoding];
                    NSString* cString = [NSString stringWithCString: encodedCString encoding: encoding];
                    // search and replace "=XX" and "_"
                     [decodedString appendString: [cString mdcStringFromQEncodedAsciiHexInCharset: encoding]];
                }
            } else {
                // unknown encoding?? assert?
            }
        }
        // append remaining suffix ascii string if it exists
        NSUInteger suffixLocation = lastCaptureRange.location + lastCaptureRange.length;
        NSUInteger suffixLength = self.length - suffixLocation;
        NSRange suffixRange = NSMakeRange(suffixLocation, suffixLength);
        [decodedString appendString: [[self substringWithRange:suffixRange] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]]];
        
        returnString = [decodedString copy];
    }
    
    return returnString;
}

-(NSString*) mdcStringFromQEncodedAsciiHexInCharset: (int) encodingCharset {
    // Change to use NSScanner
    
    // define regex above
    // find matches here
    // create empty new mutable string
    // replace matches with dehexed or spaced and append to new string
    // append intermediate range to string
    // return new string
    NSMutableString* decodedMutableString = [[NSMutableString alloc] initWithCapacity: self.length];
    
    //NSCharacterSet *replaceableCharacters = [NSCharacterSet characterSetWithCharactersInString:@"=_"];
    NSScanner* scanner = [NSScanner scannerWithString: self];
    
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
                UInt8 hexCode = [scanner mdcScanQHexUnichar];
                
                if (hexCode!=0) {
                    // valid hex code found
                    char utf8Chars[5];
                    NSUInteger unicodeIndex = 0;
                    utf8Chars[unicodeIndex] = hexCode;
                    if ((encodingCharset == NSUTF8StringEncoding) && (hexCode > 0x7f) && (scanner.string.length - scanner.scanLocation > 2)) {
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
                                hexCode = [scanner mdcScanQHexUnichar];
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
                                hexCode = [scanner mdcScanQHexUnichar];
                                if ((hexCode & 0xC0) == 0x80) {
                                    // next byte is of correct 10xxxxxx form
                                    utf8Chars[++unicodeIndex] = hexCode;
                                    currentCharacter = [scanner.string substringWithRange: NSMakeRange(scanner.scanLocation, 1)];
                                    if ([currentCharacter isEqualToString: @"="]) {
                                        // get second byte
                                        [scanner setScanLocation: ++(scanner.scanLocation)]; // skip "="
                                        hexCode = [scanner mdcScanQHexUnichar];
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
                                hexCode = [scanner mdcScanQHexUnichar];
                                if ((hexCode & 0xC0) == 0x80) {
                                    // next byte is of correct 10xxxxxx form
                                    utf8Chars[++unicodeIndex] = hexCode;
                                    currentCharacter = [scanner.string substringWithRange: NSMakeRange(scanner.scanLocation, 1)];
                                    if ([currentCharacter isEqualToString: @"="]) {
                                        // get second byte
                                        [scanner setScanLocation: ++(scanner.scanLocation)]; // skip "="
                                        hexCode = [scanner mdcScanQHexUnichar];
                                        if ((hexCode & 0xC0) == 0x80) {
                                            // next byte is of correct 10xxxxxx form
                                            utf8Chars[++unicodeIndex] = hexCode;
                                            currentCharacter = [scanner.string substringWithRange: NSMakeRange(scanner.scanLocation, 1)];
                                            if ([currentCharacter isEqualToString: @"="]) {
                                                // get second byte
                                                [scanner setScanLocation: ++(scanner.scanLocation)]; // skip "="
                                                hexCode = [scanner mdcScanQHexUnichar];
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
                        NSString* newString = [NSString stringWithCString: utf8Chars encoding: encodingCharset];
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
    
     return [decodedMutableString copy];
}

-(NSString*) mdcStringDeQuotedPrintableFromCharset: (int) encodingCharset {
    NSString* dequotedPrintable;
    

    dequotedPrintable = [self mdcStringFromQEncodedAsciiHexInCharset: encodingCharset];
    
    NSString* softReturn = @"=\r\n";
    if ([dequotedPrintable rangeOfString: softReturn].location == NSNotFound) {
        // =\r\n not found
        softReturn = @"=\n";
        if ([dequotedPrintable rangeOfString: softReturn].location == NSNotFound) {
            // no soft returns found
            softReturn = nil;
        }
    }
    
    if (softReturn) {
        NSString* unfoldedString = [dequotedPrintable stringByReplacingOccurrencesOfString: softReturn withString: @""];
        dequotedPrintable = unfoldedString;
    }
    // Replace all lines ending with "=\r\n" meaning soft return with nothing.
    
    return dequotedPrintable;
}

-(id) mdcNumberFromIANACharset {
    NSNumber* nsDomainCharset;
    
    NSDictionary* mdcCharsetMap = @{@"US-ASCII": @(NSASCIIStringEncoding),
                    @"UTF-8": @(NSUTF8StringEncoding),
                    @"ISO-8859-1": @(NSISOLatin1StringEncoding),
                    @"KOI8-R": @(NSWindowsCP1251StringEncoding),
                    @"US-ASCII2": @(NSNonLossyASCIIStringEncoding)};
    
        // should be a string
        NSString* upperCaseMimeCharset = [self uppercaseString];
        nsDomainCharset = [mdcCharsetMap objectForKey: upperCaseMimeCharset];

    return nsDomainCharset;
}

@end
