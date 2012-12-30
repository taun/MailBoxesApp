//
//  MBTokenTree.h
//  MailBoxes
//
//  Created by Taun Chapman on 12/2/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SimpleRFC822Address;

#define TokenTreeErrorDomain @"TokenTree"

#define ArrayBounds 1

/*!
 Methods are implied to apply to the next token.
 If a method returns nil, it failed and there may be an error value waiting.
 If the method returns a value, the donated token is removed from the array.
 The last token is added to the "lastToken" property.
 
 Scan always removes the token. 
 Use "peek" or "is" to not remove the token.
 */
@interface MBTokenTree : NSObject

@property (strong, nonatomic)             NSMutableArray*     tokenArray;
@property (strong, nonatomic, readonly)   id                  lastToken;
@property (strong, readonly, nonatomic)   NSError*            error;

//- (NSString *)description;

- (id) initWithArray: (NSMutableArray*) newTokens;

- (void)addObject:(id)anObject;

- (void)insertObject:(id)anObject;
- (void)removeAllObjects;
- (NSUInteger)count;

/*!
 Returns the next token regardless of type.
 Does not remove from list.
*/
-(id) peekToken;

/*!
 Returns the next token regardless of type.
 removes returned token from list.
 */
-(id) scanToken;
-(id) peekNextToken;

-(void) removeToken;
-(void) removeNextToken;

-(BOOL) isNonZeroSubTree;

-(BOOL) isNonNilString;

-(BOOL) isEmpty;

-(NSDate*) scanDateFromRFC3501Format;
-(NSDate*) scanDateFromRFC822Format;

-(BOOL) isString;
/*!
 if the token is a non-zero length string,
 does not remove the token.
 returns the string. 
 Even if "NIL"
 */
-(NSString*) peekString;
/*!
 Same as peekString but for next token.
 */
-(NSString*) peekNextString;
/*!
 if the token is a non-zero length string,
 removes the token.
 returns the string.
 Except if the string is "NIL" in which case
 nil is returned but token is still removed.
 */
-(NSString*) scanString;
-(NSString*) scanStringAsCamelCase;


-(MBTokenTree*) peekSubTree;
-(MBTokenTree*) scanSubTree;

//-(NSMutableArray*) scanArray;

-(NSNumber*) scanNumber;

-(BOOL) isNSData;
-(NSData*) peekNSData;
-(NSData*) scanNSData;

-(NSDictionary*) scanForKeyValue: (NSString*) key;

-(SimpleRFC822Address*) scanRFC822Address; 

@end
