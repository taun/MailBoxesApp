//
//  IMAPResponseBuffer.h
//  MailBoxes
//
//  Created by Taun Chapman on 8/18/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMAPResponseDelegate.h"

@class IMAPCommand;
@class IMAPCoreDataStore;
@class IMAPResponse;
@class MBTokenTree;

/*!
 @header
 
 more later
 
 */

enum IMAPParseResult {
    IMAPParseComplete = 1,
    IMAPParseWaiting,
    IMAPParseUnexpectedEnd,
    IMAPParseError,
    IMAPParseTimeOut,
    IMAPParsing
};
typedef UInt8 IMAPParseResult;

enum IMAPResponseState {
    IMAPResponseLineMode = 1,
    IMAPResponseLiteralMode,
    IMAPResponseContinuationMode
};
typedef UInt8 IMAPResponseState;

// Below, we take advantage of no already being defined as 0

/*!
 IMAPResponseBuffer which can create an IMAPResponse (a view) from the raw data.
 
 The buffer is filled by a background asynchronous inputStream in IMAPClient.
 
 Use:
    -(IMAPParseResult)parseBuffer: (IMAPResponse**)response - will parse until out of data then return a IMAPParseResult.
    caller will need to test result and either parse again or use the finished IMAPResponse.

 
 @abstract encapsulate response data
 
 */
@interface IMAPResponseBuffer : NSObject {
    id            _delegate;
    unsigned char _currentByte;
}
@property (nonatomic, weak, readwrite) IMAPCoreDataStore *clientStore;

@property (strong)  NSMutableArray            *dataBuffers;
@property (strong)  NSMutableData             *currentBuffer;
@property (assign)  unsigned char             currentByte;
@property (assign)  NSUInteger                currentCharLocation;

@property (assign)  IMAPResponseState         state;
@property (assign)  IMAPParseResult           result;
@property (assign)  BOOL                      isTagged;
@property (assign)  BOOL                      hasLiteral; // literalBuffer != nil
@property (strong)  IMAPCommand               *command;
@property (weak)    NSError                   *error;

@property (assign) NSTimeInterval             timeOutPeriod; //seconds

/*!
 designated init
 
 @param newDataBuffer NSMutableData
 */
-(void) addDataBuffer:(NSMutableData *)newDataBuffer;

-(id <IMAPResponseDelegate>)delegate;
-(void)setDelegate:(id)newDelegate;

-(IMAPParseResult) parseBuffer:(IMAPResponse* __autoreleasing *) responseAddress;


#pragma mark - Low Level Parsing utility methods
-(NSString *) copyTokensUpToNext: (char *)stopChars;
-(NSMutableArray *) copyArrayTokensTo: (char) stopChar;

-(int) incrementBytePosition;
-(int) incrementBytePositionBy: (NSUInteger) theIncrement;
-(int) decrementBytePosition;

-(NSString *) copySubTokenStringWithRange: (NSRange) tokenRange;


@end

