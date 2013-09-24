//
//  MBTokenTree.m
//  MailBoxes
//
//  Created by Taun Chapman on 12/2/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import "MBTokenTree.h"
#import "SimpleRFC822Address.h"

#include <time.h>
#include <xlocale.h>

#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_WARN;

@implementation MBTokenTree

@synthesize tokenArray=_tokens;
@synthesize lastToken=_lastToken;
@synthesize error=_error;

//- (NSString*) description {
//    NSString* theDescription = [NSString stringWithFormat: @"%@ - %@", [super description], [self.tokens description]];
//    return theDescription;
//}

- (id)init {
    return [self initWithArray: nil];
}

- (id) initWithArray:(NSMutableArray *)newTokens {
    self = [super init];
    if (self) {
        NSMutableArray* mutableTokens = nil;
        _error = nil;
        if (newTokens == nil) {
            mutableTokens = [[NSMutableArray alloc] initWithCapacity: 2];
        } else if (![newTokens isKindOfClass: [NSMutableArray class]]) {
            mutableTokens = [[NSMutableArray alloc] initWithArray: newTokens];
        } else {
            mutableTokens = newTokens;
        }
        _tokens = mutableTokens;
    }
    return self;    
}

-(void) addObject:(id)anObject {
    [self.tokenArray addObject: anObject];
}

- (void)insertObject:(id)anObject {
    [self.tokenArray insertObject: anObject atIndex: 0];
}

- (void)removeAllObjects {
    [self.tokenArray removeAllObjects];
}

- (NSUInteger)count {
    return [self.tokenArray count];
}

-(BOOL) isEmpty {
    BOOL result = NO;
    if ([self count] == 0) {
        result = YES;
    }
    return result;
}

-(id) peekToken {
    id result = nil;
    _error = nil;
    
    if ([self.tokenArray count]>0) {
        result = [self.tokenArray objectAtIndex: 0];
    } else {
        DDLogError(@"%@-%@ array bounds error. Attempt to access an empty array", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
        
        _error = [NSError errorWithDomain: TokenTreeErrorDomain code: ArrayBounds userInfo: nil];
    }
    return result;
}

-(id) scanToken {
    id result = [self peekToken];
    [self removeToken];
    return result;
}

-(id) peekNextToken {
    id result = nil;
    _error = nil;
    
    if ([self.tokenArray count]>=2) {
        result = [self.tokenArray objectAtIndex: 1];
    } else {
        DDLogError(@"%@-%@ array bounds error. Attempt to access an empty array", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
        
        _error = [NSError errorWithDomain: TokenTreeErrorDomain code: ArrayBounds userInfo: nil];
    }
    return result;
}

-(void) removeToken {
    if ([self.tokenArray count]>0) {
        [self.tokenArray removeObjectAtIndex: 0];
    } else {
        DDLogError(@"%@-%@ array bounds error. Attempt to access an empty array", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
        
        _error = [NSError errorWithDomain: TokenTreeErrorDomain code: ArrayBounds userInfo: nil];
    }
}

-(void) removeNextToken {
    if ([self.tokenArray count]>=2) {
        [self.tokenArray removeObjectAtIndex: 1];
    } else {
        DDLogError(@"%@-%@ array bounds error. Attempt to access an empty array", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
        
        _error = [NSError errorWithDomain: TokenTreeErrorDomain code: ArrayBounds userInfo: nil];
    }
}

-(BOOL) isNonZeroSubTree {
    BOOL result = NO;
    id next = [self peekToken];
    if ([next isKindOfClass: [NSMutableArray class]]) {
        if ([(NSMutableArray*)next count] > 0) {
            result = YES;
        }
    }
    return result;
}

-(MBTokenTree*) peekSubTree {
    MBTokenTree* result = nil;
    if ([self isNonZeroSubTree]) {
        result = [[MBTokenTree alloc] initWithArray: [self peekToken]];
    }
    return  result;
}

-(MBTokenTree*) scanSubTree {
    MBTokenTree* result = nil;
    result = [self peekSubTree];
    if (result) {
        [self removeToken];
    }
    return result;
}

-(BOOL) isString {
    BOOL result = NO;
    id next = [self peekToken];
    if ([next isKindOfClass: [NSString class]]) {
        if ([(NSString*)next length]>0) {
                result = YES;
        }
    }
    return result;
}

-(BOOL) isNonNilString {
    BOOL result = NO;
    id next = [self peekToken];
    if ([next isKindOfClass: [NSString class]]) {
        if ([(NSString*)next length]>0) {
            if (!([(NSString*)next caseInsensitiveCompare: @"NIL"] == NSOrderedSame)) {
                result = YES;
            }
        }
    }
    return result;
}

-(NSString*) peekString {
    NSString* result = nil;
    if ([self isString]) {
        result = [self peekToken];
    }
    return result;
}

-(NSString*) peekNextString {
    NSString* result = nil;
    id next = nil;
    if ((next = [self peekNextToken])) {
        if ([next isKindOfClass: [NSString class]]) {
            if ([(NSString*)next length]>0) {
                    result = (NSString*) next;
            }
        }
        
    }
    return result;
}

-(NSString*) scanString {
    NSString* result = nil;
    result = [self peekString];
    if (result) {
        [self removeToken];
        if (([result caseInsensitiveCompare: @"NIL"] == NSOrderedSame)) {
            result = nil;
        }
    }
    return result;
}

-(NSNumber*) scanNumber {
    NSNumber* result = nil;
    
    NSString* text = nil;
    if ((text = [self scanString])) {
        NSInteger tempArg = [text longLongValue];
        if (tempArg != 0) {
            result = [NSNumber numberWithInteger:tempArg];
        }
    }
    return result;
}

/*!
 Assumes a key value token pair.
 
 @param key key to find in the MBTokenTree
 @return NSDictionary of token key/value
 */
-(NSDictionary*) scanForKeyValue: (NSString*) key {
    BOOL keyFound = NO;
    NSUInteger valueIndex = 0;
    
    NSDictionary* result = nil;
    
    for (id element in self.tokenArray) {
        if (keyFound) {
            // element after key is found
            result = [[NSDictionary alloc] initWithObjectsAndKeys: element, key, nil];
            break;
        } else {
            if ([element isKindOfClass: [NSString class]]) {
                if ([((NSString*) element) caseInsensitiveCompare: key] == NSOrderedSame) {
                    keyFound = YES;
                }
            }
        }
        valueIndex++;
    }
    [self.tokenArray removeObjectAtIndex: valueIndex];
    [self.tokenArray removeObjectAtIndex: valueIndex -1];
    return result;
}

/*!
 RFC822 Header Format = Tue, 12 Feb 2008 09:36:17 -0500
 INTERNALDATE Format =  "26-Jul-2011 07:48:41 -0400"
 */
-(NSDate *) scanDateFromRFC3501Format {
    NSDate* internalDate = nil;
    NSString* next = nil;
    if ((next = [self scanString])) {
        
        struct tm  sometime;
        const char *rfc3501DateFormat = "%e-%b-%Y %H:%M:%S %z";
        char* transformResult = strptime_l([next cStringUsingEncoding: NSUTF8StringEncoding], rfc3501DateFormat, &sometime, NULL);
        
        if (transformResult != NULL) {
            internalDate = [NSDate dateWithTimeIntervalSince1970: mktime(&sometime)];
            
        }
    }
    
    return internalDate;
}
/*!
 RFC822 Header Format = Tue, 12 Feb 2008 09:36:17 -0500
 RFC822 Header Format = Tue, 12 Feb 2008 09:36:17 "GMT"  obsolete
 */
-(NSDate *) scanDateFromRFC822Format {
    NSDate *internalDate = nil;
    static NSDateFormatter *sRFC2822DateFormatter = nil;
    //NSDateFormatter *dateFormatter;
    NSLocale *enUSPOSIXLocale;
    
    static NSRegularExpression *sLocateRFC2822Date = nil;
    NSError *regexError;
    
    NSString* next = nil;
    if ((next = [self scanString])) {
        if (sRFC2822DateFormatter==nil) {
            sRFC2822DateFormatter = [[NSDateFormatter alloc] init];
            enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            
            [sRFC2822DateFormatter setLocale:enUSPOSIXLocale];
            [sRFC2822DateFormatter setDateFormat:@"dd MMM yyyy HH:mm:ss"];
            
            sLocateRFC2822Date = [[NSRegularExpression alloc] initWithPattern: @"(\\d{1,2} \\w{3} \\d{4} \\d{2}:\\d{2}:\\d{2})\\s(.\\d{4})|(\\d{1,2} \\w{3} \\d{4} \\d{2}:\\d{2}:\\d{2})\\s?\"?(\\w{3})"
                                                                      options: 0 
                                                                        error: &regexError];
        }
        NSTextCheckingResult *dateFound = [sLocateRFC2822Date firstMatchInString: next 
                                                                         options: 0 
                                                                           range:NSMakeRange(0, [next length])];
        
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
                timeZoneString = [next substringWithRange: range2];
                NSInteger timeZoneDecimal100Hours = [timeZoneString integerValue];
                messageTimeZone = [NSTimeZone timeZoneForSecondsFromGMT: timeZoneDecimal100Hours*60*60/100];
                dateRange = range1;
                
                //DDLogVerbose(@"%@\n",[stringWithRFC2822Date substringWithRange: [dateFound rangeAtIndex: 1]]);
                //DDLogVerbose(@"%@\n",[stringWithRFC2822Date substringWithRange: [dateFound rangeAtIndex: 2]]);
            } else if (range3.length >0 && range4.length > 0) {
                // 2nd type
                timeZoneString = [next substringWithRange: range4];
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
                                        forString: next 
                                            range: &dateRange  
                                            error: &regexError];
        }
        
    }
    
    return internalDate;
}

-(NSString *) scanStringAsCamelCase {
    // commands like READ-ONLY become ReadOnly
    NSString *normalized = nil;
    if ((normalized = [self scanString])) {
        normalized = [normalized capitalizedString];
        normalized = [normalized stringByReplacingOccurrencesOfString: @"-" withString: @""];
        normalized = [normalized stringByReplacingOccurrencesOfString: @"." withString: @""];
        normalized = [normalized stringByReplacingOccurrencesOfString: @"[" withString: @""];
        normalized = [normalized stringByReplacingOccurrencesOfString: @"]" withString: @""];
    }
    return normalized;
}

-(SimpleRFC822Address*) scanRFC822Address {
    SimpleRFC822Address* rfcaddress = nil;
    NSString* next = nil;
    if ((next = [self scanString])) {
        rfcaddress = [[SimpleRFC822Address alloc] init];
        rfcaddress.name = next;
        rfcaddress.email = next;
    }
    return rfcaddress;
}

-(BOOL) isNSData {
    BOOL result = NO;
    id next = [self peekToken];
    if ([next isKindOfClass: [NSData class]]) {
        if ([(NSData*)next length]>0) {
            result = YES;
        }
    }
    return result;
}

-(NSData*) peekNSData {
    NSData* result = nil;
    if ([self isNSData]) {
        result = [self peekToken];
    }
    return result;
}

-(NSData*) scanNSData {
    NSData* result = nil;
    result = [self peekNSData];
    if (result) {
        [self removeToken];
    }
    return result;
}


@end
