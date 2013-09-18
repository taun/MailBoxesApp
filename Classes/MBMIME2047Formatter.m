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

static NSDictionary *charsetMap;

@implementation MBMIME2047Formatter

+(void)initialize {
    NSError *error=nil;
    regexEncodingFields = [[NSRegularExpression alloc] initWithPattern: @"=\\?([A-Z0-9\\-]+)\\?(?:(?:[bB]\\?([+/0-9A-Za-z]*=*))|(?:[qQ]\\?([a-zA-Z0-9!=\\-]*)))\\?="
                                                               options: NSRegularExpressionCaseInsensitive
                                                                 error: &error];
    if (error) {
        NSLog(@"Error: %@", error);
    }
    
    charsetMap = [[NSDictionary alloc] initWithObjectsAndKeys: [NSNumber numberWithInt: NSASCIIStringEncoding], @"US-ASCII",
                  [NSNumber numberWithInt: NSUTF8StringEncoding], @"UTF-8",
                  [NSNumber numberWithInt: NSISOLatin1StringEncoding], @"ISO-8859-1",
                  [NSNumber numberWithInt: NSWindowsCP1251StringEncoding], @"KOI8-R",
                  [NSNumber numberWithInt: NSNonLossyASCIIStringEncoding], @"US-ASCII2",
                  nil];
}

-(NSString*) replaceQEncodedHexAndSpaceIn: (NSString*) hexedString encoding: (int) encodingCharset {
    // define regex above
    // find matches here
    // create empty new mutable string
    // replace matches with dehexed or spaced and append to new string
    // append intermediate range to string
    // return new string
    NSMutableString* decodedMutableString = [[NSMutableString alloc] initWithCapacity: hexedString.length];
    
    
    return [decodedMutableString copy];
}
/*!
 @param anObject
 The object for which a textual representation is returned.
 
 @result
 An NSString object that textually represents object for display. Returns nil if object is not of the correct class.
 
 @discussion
 When implementing a subclass, return the NSString object that textually represents the cell’s object for display and—if editingStringForObjectValue: is unimplemented—for editing. First test the passed-in object to see if it’s of the correct class. If it isn’t, return nil; but if it is of the right class, return a properly formatted and, if necessary, localized string. (See the specification of the NSString class for formatting and localizing details.)
 
 */
- (NSString *)stringForObjectValue:(id)anObject {

    NSArray* matches;
    
    if ([anObject isKindOfClass:[NSString class]]) {
        NSInteger length = [(NSString*)anObject length];
        matches = [regexEncodingFields matchesInString: anObject options: 0 range: NSMakeRange(0, length)];
    }
    
//    [regexEncodingFields enumerateMatchesInString: anObject
//                                       options:0
//                                         range: NSMakeRange(0, [anObject length])
//                                    usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
//                                        
//                                        NSString *charset;
//                                        NSString *encoding;
//                                        NSString *encoded;
//                                        
//                                        NSLog(@"match ranges: %u", match.numberOfRanges);
//                                        
//                                        if (match.numberOfRanges==3) {
//                                            charset = [[anObject substringWithRange: [match rangeAtIndex: 0]] uppercaseString];
//                                            encoding = [[anObject substringWithRange: [match rangeAtIndex: 1]] uppercaseString];
//                                            encoded = [anObject substringWithRange: [match rangeAtIndex: 2]];
//
//                                        }
//                                        
//                                        [result appendString: charset];
//                                        [result appendString: encoding];
//                                        [result appendString: encoded];
//                                    }];
    
    NSInteger fullRangeIndex = 0;
    NSInteger charsetRangeIndex = 1;
    NSInteger bCodeRangeIndex = 2;
    NSInteger qCodeRangeIndex = 3;
    // rangge length 0 means not found
    
    NSString* charsetString;
    NSString* encodedData;
    NSMutableString* decodedString = [NSMutableString new];

    if (matches.count==0) {
        decodedString = anObject;
    } else {
        for (NSTextCheckingResult* tcr in matches) {
            
            if ([tcr rangeAtIndex: charsetRangeIndex].length != 0) {
                charsetString = [[(NSString*)anObject substringWithRange: [tcr rangeAtIndex: charsetRangeIndex]] uppercaseString];
            }
            
            NSRange encodedRange;
            if ([tcr rangeAtIndex: bCodeRangeIndex].length != 0) {
                // b encoded
                encodedRange = [tcr rangeAtIndex: bCodeRangeIndex];
                if (encodedRange.length !=0) {
//                    NSString* encodedString = [(NSString*)anObject substringWithRange: encodedRange];
//                    const char* encodedCString
//                    [decodedString appendString: encodedString];
                }
            } else if ([tcr rangeAtIndex: qCodeRangeIndex].length != 0) {
                // q encoded
                encodedRange = [tcr rangeAtIndex: qCodeRangeIndex];
                if (encodedRange.length !=0) {
                    int encoding = [[charsetMap objectForKey: charsetString] intValue];
                    NSString* encodedString = [(NSString*)anObject substringWithRange: encodedRange];
                    const char* encodedCString = [encodedString cStringUsingEncoding: NSASCIIStringEncoding];
                    NSString* decodedCString = [NSString stringWithCString: encodedCString encoding: encoding];
                    // search and replace "=XX" and "_"
                    NSString* fullyDecodedString = [self replaceQEncodedHexAndSpaceIn: decodedCString encoding: encoding];
                    [decodedString appendString: decodedCString];
                }
            } else {
                // unknown encoding?? assert?
            }
        }
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
 @param anObject
 If conversion is successful, upon return contains the object created from string.
 
 @param string
 The string to parse.
 
 @param error
 If non-nil, if there is a error during the conversion, upon return contains an NSString object that describes the problem.
 
 @result
 YES if the conversion from string to cell content object was successful, otherwise NO.
 
 @discussion
 When implementing a subclass, return by reference the object anObject after creating it from string. Return YES if the conversion is successful. If you return NO, also return by indirection (in error) a localized user-presentable NSString object that explains the reason why the conversion failed; the delegate (if any) of the NSControl object managing the cell can then respond to the failure in control:didFailToFormatString:errorDescription:. However, if error is nil, the sender is not interested in the error description, and you should not attempt to assign one.
 
 */
- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error {
    BOOL result = NO;
    
    
    return result;
}

@end
