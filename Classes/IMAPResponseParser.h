//
//  IMAPResponseParser.h
//  MailBoxes
//
//  Created by Taun Chapman on 8/18/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMAPResponseDelegate.h"
#import "IMAPClientStore.h"

@class IMAPCommand;
@class IMAPCoreDataStore;
@class IMAPParsedResponse;
@class MBTokenTree;

/*!
 @header
 
 more later
 
 */

enum IMAPParseResult {
    IMAPParsingNotStarted = 0,
    IMAPParseComplete,
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

@protocol IMAPResponseParserDelegate <NSObject>

-(void) parseComplete: (IMAPParsedResponse*) parsedResponse;
-(void) parseWaiting: (IMAPParsedResponse*) parsedResponse;
-(void) parseUnexpectedEnd: (IMAPParsedResponse*) parsedResponse;
-(void) parseError: (IMAPParsedResponse*) parsedResponse;
-(void) parseTimeout: (IMAPParsedResponse*) parsedResponse;

@end

// Below, we take advantage of no already being defined as 0

/*!
 IMAPResponseBuffer which can create an IMAPResponse (a view) from the raw data.
 
 The buffer is filled by a background asynchronous inputStream in IMAPClient.
 
 ### Use:
 
    -(IMAPParseResult)parseBuffer: (IMAPResponse**)response - will parse until out of data then return a IMAPParseResult.

 caller will need to test result and either parse again or use the finished IMAPResponse.

 
 
 */
@interface IMAPResponseParser : NSObject {
    id            _delegate;
    unsigned char _currentByte;
    dispatch_queue_t _parserQueue;
}
@property (nonatomic, weak, readwrite) id<IMAPDataStore>    defaultDataStore;
@property (nonatomic,strong)  IMAPParsedResponse            *parsedResponse;
@property (weak)  id<IMAPParsedResponseDelegate>            responseDelegate;
@property (weak)  id<IMAPResponseParserDelegate>            bufferDelegate;
@property (strong)  NSMutableArray                          *dataBuffers;
@property (strong)  NSMutableData                           *currentBuffer;
@property (assign)  unsigned char                           currentByte;
@property (assign)  NSUInteger                              currentCharLocation;

@property (readonly) BOOL                     running;
@property (assign)  IMAPResponseState         state;
@property (assign)  IMAPParseResult           result;
@property (assign)  BOOL                      isTagged;
@property (assign)  BOOL                      hasLiteral; // literalBuffer != nil
@property (strong)  IMAPCommand               *command;
@property (weak)    NSError                   *error;

@property (assign) NSTimeInterval             timeOutPeriod; //seconds

/// @name Property convenience methods
+ (NSString*) resultAsString: (IMAPParseResult) aResult;
+ (NSString*) stateAsString: (IMAPResponseState) aState;

+(instancetype) newResponseBufferWithDefaultStore: (IMAPCoreDataStore*) store;
-(void) addDataBuffer:(NSMutableData *)newDataBuffer;
/*!
 Start parsing in the background.
 */
-(void) startParsing;
/*!
 Stop background parsing.
 */
-(void) stopParsing;
-(void) reset;


#pragma mark - Low Level Parsing utility methods
-(NSString *) copyTokensUpToNext: (char *)stopChars;
-(NSMutableArray *) copyArrayTokensTo: (char) stopChar;

-(int) incrementBytePosition;
-(int) incrementBytePositionBy: (NSUInteger) theIncrement;
-(int) decrementBytePosition;

-(NSString *) copySubTokenStringWithRange: (NSRange) tokenRange;


@end

