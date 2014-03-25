//
//  MBTokenTree.m
//  MailBoxes
//
//  Created by Taun Chapman on 12/2/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import "MBTokenTree.h"
#import <MoedaeMailPlugins/SimpleRFC822Address.h>
#import <MoedaeMailPlugins/NSDate+IMAPConversions.h>

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
#pragma message "ToDo: the peekToken ArrayBounds errors are not really errors. They occurr when purposefully looking to detect the end of the tokens."
-(id) peekToken {
    id result = nil;
    _error = nil;
    
    if ([self.tokenArray count]>0) {
        result = (self.tokenArray)[0];
    } else {
        DDLogVerbose(@"%@-%@ array bounds error. Attempt to access an empty array", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
        
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
        result = (self.tokenArray)[1];
    } else {
        DDLogVerbose(@"%@-%@ array bounds error. Attempt to access an empty array", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
        
        _error = [NSError errorWithDomain: TokenTreeErrorDomain code: ArrayBounds userInfo: nil];
    }
    return result;
}

-(void) removeToken {
    if ([self.tokenArray count]>0) {
        [self.tokenArray removeObjectAtIndex: 0];
    } else {
        DDLogVerbose(@"%@-%@ array bounds error. Attempt to access an empty array", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
        
        _error = [NSError errorWithDomain: TokenTreeErrorDomain code: ArrayBounds userInfo: nil];
    }
}

-(void) removeNextToken {
    if ([self.tokenArray count]>=2) {
        [self.tokenArray removeObjectAtIndex: 1];
    } else {
        DDLogVerbose(@"%@-%@ array bounds error. Attempt to access an empty array", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
        
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
            result = @(tempArg);
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
            result = @{key: element};
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
        
        internalDate = [NSDate newDateFromRFC3501FormatString: next];
    }
    
    return internalDate;
}
/*!
 RFC822 Header Format = Tue, 12 Feb 2008 09:36:17 -0500
 RFC822 Header Format = Tue, 12 Feb 2008 09:36:17 "GMT"  obsolete
 */
-(NSDate *) scanDateFromRFC822Format {
    NSDate *internalDate = nil;

    NSString* next = nil;
    if ((next = [self scanString])) {
        internalDate = [NSDate newDateFromRFC822FormatString: next];
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

#pragma message "ToDo: change to use SimpleRFC822Address newAddressFromString: code. Or better yet GroupAddress..."
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
