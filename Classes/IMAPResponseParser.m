//
//  IMAPResponseParser.m
//  MailBoxes
//
//  Created by Taun Chapman on 8/18/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import "IMAPResponseParser.h"
#import "IMAPParsedResponse.h"
#import "IMAPCommand.h"
#import "IMAPCoreDataStore.h"

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

static const int ddLogLevel = LOG_LEVEL_INFO;

#define kMBLOOPSECONDS 0.01

@interface IMAPResponseParser ()
@property (nonatomic,readonly) dispatch_queue_t         delegateQueue;
/*!
 Flag to stop/cancel parsing in the background.
 */
@property (nonatomic,assign) BOOL                       stop;

-(void) parsing;
-(void) clearParsedData;
@end

@implementation IMAPResponseParser

+ (NSString*) resultAsString: (IMAPParseResult) aResult {
    NSString* typeString = nil;
    
    switch (aResult) {
        case IMAPParsingNotStarted:
            typeString = @"IMAPParsingNotStarted";
            break;
        case IMAPParseComplete:
            typeString = @"IMAPParseComplete";
            break;
        case IMAPParseWaiting:
            typeString = @"IMAPParseWaiting";
            break;
        case IMAPParseUnexpectedEnd:
            typeString = @"IMAPParseUnexpectedEnd";
            break;
        case IMAPParseError:
            typeString = @"IMAPParseError";
            break;
        case IMAPParseTimeOut:
            typeString = @"IMAPParseTimeOut";
            break;
        case IMAPParsing:
            typeString = @"IMAPParsing";
            break;
            
        default:
            break;
    }
    return typeString;
}

+ (NSString*) stateAsString: (IMAPResponseState) aState {
    NSString* typeString = nil;
    
    switch (aState) {
        case IMAPResponseLineMode:
            typeString = @"IMAPResponseLineMode";
            break;
        case IMAPResponseLiteralMode:
            typeString = @"IMAPResponseLiteralMode";
            break;
        case IMAPResponseContinuationMode:
            typeString = @"IMAPResponseContinuationMode";
            break;
            
        default:
            break;
    }
    return typeString;
}

#pragma mark - initialization and dealloc
+(instancetype) newResponseBufferWithDefaultStore:(IMAPCoreDataStore *)store {
    IMAPResponseParser* newRB = [[[self class] alloc] init];
    newRB.defaultDataStore = store;
    return newRB;
}
- (id)init {
    self = [super init];
    if (self) {
        // Initialization code here.
        _dataBuffers = [[NSMutableArray alloc] initWithCapacity: 2];
        _currentBuffer = nil;
        _currentCharLocation = 0;
        _currentByte = 0;
        
        _isTagged = NO;
        _hasLiteral = NO;
        _command = nil;
        _error = nil;
        
        _state = 1;
        _result = 0;
        
        _timeOutPeriod = -2; //seconds
        
        _running = NO;
        _stop = YES;
        
        _parserQueue = dispatch_queue_create("parser queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}
-(void) dealloc {
    _stop = YES;
    // give the block a chance to stop?
    NSDate* loopInterval = [NSDate dateWithTimeIntervalSinceNow: kMBLOOPSECONDS];
    [[NSRunLoop currentRunLoop] runUntilDate: loopInterval];
    
    self.bufferDelegate = nil;
}
-(dispatch_queue_t) delegateQueue {
    return dispatch_get_main_queue();
}
-(IMAPParsedResponse*) parsedResponse {
    if (!_parsedResponse) {
        _parsedResponse = [[IMAPParsedResponse alloc] init];
        [_parsedResponse setDelegate: self.responseDelegate];
        if (self.command && self.command.dataStore) {
            [_parsedResponse setDataStore: self.command.dataStore];
        } else {
            [_parsedResponse setDataStore: self.defaultDataStore];
        }
    }
    return _parsedResponse;
}
-(void) cacheCurrentByte {
    unsigned char aBuffer[2];
    [self.currentBuffer getBytes: aBuffer range: NSMakeRange(self.currentCharLocation, 1)];
    self.currentByte = aBuffer[0];
}
-(void) resetCurrentCharLocation {
    self.currentCharLocation = 0;
    [self cacheCurrentByte];
}
-(void) addDataBuffer:(NSMutableData *)newDataBuffer {
    if ([self.dataBuffers count]==0) {
        //fresh new buffer from scratch
        [self.dataBuffers addObject: newDataBuffer];
        self.currentBuffer = (self.dataBuffers)[0];
        [self resetCurrentCharLocation];
    } else {
        // appending buffer to be used later
        [self.dataBuffers addObject: newDataBuffer];
    }
    if (!_running && !_stop) {
        [self startParsing];
    }
}
- (NSString *) description {
    NSString *formattedDescription;
    formattedDescription = [NSString stringWithFormat: @"%@: dataBuffers: %lu, Position: %lu",
                            [self className], (unsigned long)[_dataBuffers count], _currentCharLocation];
    return formattedDescription;
}
/*!
 For debugging purposes
 length 60
 curchar 21
 */
- (NSString *) bufferPeek {
    NSMutableString *peek = nil;
    NSString * staticString;
    NSInteger halfWidth = 20;
    NSUInteger rangeLocation;
    NSUInteger rangeLength = (halfWidth * 2) + 1;
    NSUInteger selectedLocation;
    
    if (self.currentCharLocation < halfWidth ) {
        rangeLocation = 0;
        selectedLocation = 0;
    } else {
        rangeLocation = self.currentCharLocation - halfWidth;
        selectedLocation = halfWidth;
    }
    
    staticString = [self copySubTokenStringWithRange: NSMakeRange(rangeLocation, rangeLength)];
    
    peek = [staticString mutableCopy];
    [peek insertString: @"<" atIndex: selectedLocation];
    [peek insertString: @">" atIndex: selectedLocation+2];
    staticString = [peek copy];
    return staticString;
}


#pragma mark - main method
-(void) parsing {
    
    //    self.result = IMAPParseError;
    
    _running = YES;
    @autoreleasepool {
        while (self.dataBuffers.count > 0 && !self.stop) {
            
            if (self.parsedResponse != nil) {
                NSMutableArray *returnedTokens;
                NSString       *returnedString;
                
                self.result = IMAPParsing;
                
                [self.parsedResponse setCommand: self.command];
                
                while ( (self.currentByte != 0) && ((self.result == IMAPParsing) || (self.result == IMAPParseWaiting))) {
#pragma message "TODO: create test & add code to break out of loop if it runs too many iterations without progress, was happening with bad \" "
                    
                    if (self.currentByte == '[') {
                        // get all in brackets
                        if ([self incrementBytePosition] == 0) {
                            returnedTokens = [self copyArrayTokensTo: ']'];
                            [self.parsedResponse.tokens addObject: returnedTokens];
                        } else {
                            self.result = IMAPParseUnexpectedEnd;
                        }
                        
                    } else if (self.currentByte == '(') {
                        // recurse parenthesis
                        if ([self incrementBytePosition] == 0) {
                            returnedTokens = [self copyArrayTokensTo: ')'];
                            [self.parsedResponse.tokens addObject: returnedTokens];
                        } else {
                            self.result = IMAPParseUnexpectedEnd;
                        }
                        
                    } else if (self.currentByte == '{') {
                        // get number in curly brackets
                        if ([self incrementBytePosition] == 0) {
                            returnedString = [self copyTokensUpToNext: "}"];
                            NSInteger literalValue = [returnedString integerValue];
                            if ([self incrementBytePosition] == 0) {
                                NSRange literalRange = NSMakeRange(self.currentCharLocation, literalValue);
                                if (self.currentBuffer.length >= (literalRange.location+literalRange.length)) {
                                    NSString *literalString = [[NSString alloc] initWithData: [self.currentBuffer subdataWithRange: literalRange] encoding: NSASCIIStringEncoding];
                                    [self.parsedResponse.tokens addObject: literalString];
                                } else {
                                    // buffer is too short
                                    self.result = IMAPParseUnexpectedEnd;
                                }
                            } else {
                                self.result = IMAPParseUnexpectedEnd;
                            }
                        } else {
                            self.result = IMAPParseUnexpectedEnd;
                        }
                        // self.hasLiteral = YES;
                        
                    } else if (self.currentByte == '"') {
                        // get up to next quote char
                        if ([self incrementBytePosition] == 0) {
                            returnedString = [self copyTokensUpToNext:"\""];
                            [self.parsedResponse.tokens addObject: returnedString];
                            if ([self incrementBytePosition] != 0) {
                                self.result = IMAPParseUnexpectedEnd;
                            }
                        } else {
                            self.result = IMAPParseUnexpectedEnd;
                        }
                        
                    } else if (self.currentByte == '\r') {
                        // next character should always be \n
                        [self incrementBytePosition];
                        if (self.currentByte == '\n') {
                            self.result = IMAPParseComplete;
                            [self incrementBytePosition];
                        } else {
                            self.result = IMAPParseUnexpectedEnd;
                        }
                    } else if (self.currentByte != ' ') {
                        // start of token
                        returnedString = [self copyTokensUpToNext:" \r"];
                        if (returnedString) {
                            [self.parsedResponse.tokens addObject: returnedString];
                        }
                        
                    } else if (self.currentByte == ' ') {
                        if ([self incrementBytePosition] != 0) {
                            self.result = IMAPParseUnexpectedEnd;
                        }
                    }
                }
                
                [self clearParsedData];
            }
            if (self.bufferDelegate) {
                IMAPParsedResponse* sendResponse = self.parsedResponse;
                [self setParsedResponse: nil];
                if (self.result == IMAPParseComplete) {
                    dispatch_async(self.delegateQueue, ^{
                        [self.bufferDelegate parseComplete: sendResponse];
                    });
                } else if (self.result == IMAPParseWaiting) {
                    dispatch_async(self.delegateQueue, ^{
                        [self.bufferDelegate parseWaiting: sendResponse];
                    });
                } else if (self.result == IMAPParseUnexpectedEnd) {
                    dispatch_async(self.delegateQueue, ^{
                        [self.bufferDelegate parseUnexpectedEnd: sendResponse];
                    });
                } else if (self.result == IMAPParseError) {
                    dispatch_async(self.delegateQueue, ^{
                        [self.bufferDelegate parseError: sendResponse];
                    });
                } else if (self.result == IMAPParseTimeOut) {
                    dispatch_async(self.delegateQueue, ^{
                        [self.bufferDelegate parseTimeout: sendResponse];
                    });
                }
            }
            NSDate* loopInterval = [NSDate dateWithTimeIntervalSinceNow: kMBLOOPSECONDS];
            [[NSRunLoop currentRunLoop] runUntilDate: loopInterval];
        }
    }
    _running = NO;
}
-(void) startParsing {
    self.stop = NO;
    if (!_running) {
        dispatch_async(_parserQueue, ^{
            //
            [self parsing];
        });
    }
}
-(void) stopParsing {
    self.stop = YES;
}
-(void) reset {
    
}

#pragma mark - low level parsing methods

-(BOOL) isBufferAtEnd {
    return (self.currentCharLocation >= [self.currentBuffer length]);
}

-(int) incrementBytePositionBy:(NSUInteger)theIncrement {
    int bufferError = 0;
    
    self.currentCharLocation+= theIncrement;
    if ([self isBufferAtEnd]) {
        // end of the buffer, see if there is another or wait for timeout
        if ([self.dataBuffers count]>1) {
            [self.currentBuffer appendData: (self.dataBuffers)[1]];
            [self.dataBuffers removeObjectAtIndex: 1];
        } else {
            if (self.result == IMAPParseComplete) {
                // discard buffer
                [self.dataBuffers removeObjectAtIndex: 0];
                self.currentCharLocation = 0;
                self.currentByte = 0;
            } else {
                // wait for timeout seconds for more data
                // set bufferState = empty
                self.currentByte = 0;
                self.result = IMAPParseWaiting;
                
                // Timeout loop here
                NSDate *now = [NSDate date];
                
                // time interval is increasing negative
                while ([now timeIntervalSinceNow] > self.timeOutPeriod && [self isBufferAtEnd]) {
                    @autoreleasepool {
                        NSDate* loopInterval = [NSDate dateWithTimeIntervalSinceNow: kMBLOOPSECONDS];
                        [[NSRunLoop currentRunLoop] runUntilDate: loopInterval];
                    }
                    // check for new buffer avail
                    if ([self.dataBuffers count] > 1) {
                        [self.currentBuffer appendData: (self.dataBuffers)[1]];
                        [self.dataBuffers removeObjectAtIndex: 1];
                    }
                }
                
                //return if timedOut
                if ([self isBufferAtEnd]) {
                    self.result = IMAPParseUnexpectedEnd;
                    bufferError = 1; // out of buffer error
                }
            }
        }
    }
    if (!bufferError) {
        [self cacheCurrentByte];
    }
    return bufferError; // no error?
}

-(int) incrementBytePosition {
    return [self incrementBytePositionBy: 1];
}

-(int) decrementBytePosition {
    
    if (self.currentCharLocation == 0) {
        self.currentByte = 0;
        return 1; // out of buffer error
    } else {
        self.currentCharLocation--;
        
        [self cacheCurrentByte];
        return 0; // no error?
    }
    
}

-(void) clearParsedData {
    if (self.currentCharLocation > 0 && ![self isBufferAtEnd]) {
        [self.currentBuffer replaceBytesInRange: NSMakeRange(0, self.currentCharLocation) withBytes:NULL length:0];
        [self resetCurrentCharLocation];
    }
}

-(NSMutableArray *) copyArrayTokensTo: (char) stopChar {
    self.result = IMAPParsing;
    
    char stoppers[5];
    stoppers[0] = 32; // space
    stoppers[1] = stopChar;
    stoppers[2] = 13; // \r
    stoppers[3] = 0; //NULL terminate
    
    NSMutableArray *tempTokens = [[NSMutableArray alloc] init];
    NSMutableArray *returnedTokens;
    NSString       *returnedString;
    
    while ( ((self.result == IMAPParsing) || (self.result == IMAPParseWaiting)) && (self.currentByte != stopChar) && (self.currentByte != 0)) {
        
        if (self.currentByte == '(') {
            // get sub tokens as array
            if ([self incrementBytePosition] == 0) {
                returnedTokens = [self copyArrayTokensTo: ')'];
                [tempTokens addObject: returnedTokens];
            } else {
                self.result = IMAPParseUnexpectedEnd;
            }
            
        } else if (self.currentByte == '"') {
            // get all of quoted string
            if ([self incrementBytePosition] == 0) {
                returnedString = [self copyTokensUpToNext: "\""];
                [tempTokens addObject: returnedString];
                if ([self incrementBytePosition] !=0 ) {
                    self.result = IMAPParseUnexpectedEnd;
                }
            } else {
                self.result = IMAPParseUnexpectedEnd;
            }
            
        } else if (self.currentByte == '[') {
            // get all in brackets
            if ([self incrementBytePosition] == 0) {
                returnedTokens = [self copyArrayTokensTo: ']'];
                [tempTokens addObject: returnedTokens];
            } else {
                self.result = IMAPParseUnexpectedEnd;
            }
            
        }else if (self.currentByte == '{') {
            // get number in curly brackets
            if ([self incrementBytePosition] == 0) {
                returnedString =  [self copyTokensUpToNext: "}"];
                NSInteger literalValue = [returnedString integerValue];
                if ([self incrementBytePositionBy: 3] != 0) {
                    self.result = IMAPParseUnexpectedEnd;
                }; //skip } and \r\n
                
                NSRange literalRange = NSMakeRange(self.currentCharLocation, literalValue);
                returnedString = [self copySubTokenStringWithRange: literalRange];
                // self.hasLiteral = YES;
                if (returnedString != nil) {
                    [tempTokens addObject: returnedString];
                    [self incrementBytePositionBy: literalValue];
                } else {
                    self.result = IMAPParseUnexpectedEnd;
                }
            } else {
                self.result = IMAPParseUnexpectedEnd;
            }
            
        } else if (self.currentByte == ' ') {
            if ([self incrementBytePosition] != 0) {
                self.result = IMAPParseUnexpectedEnd;
            };
            
        } else {
            // get space separated token
            char stoppers2[5];
            stoppers2[0] = 32; // space
            stoppers2[1] = stopChar;
            stoppers2[3] = 13; // \r
            stoppers2[2] = '['; // special case to handle no space separated "BODY[ ]" in "( )" should add "{" ?
            stoppers2[4] = 0; //NULL terminate
            
            returnedString = [self copyTokensUpToNext: stoppers2];
            [tempTokens addObject: returnedString];
            // set aTemp to ")" if it was what terminated above
        }
        
    }
    [self incrementBytePosition];
    
    return tempTokens;
}
#pragma message "TODO: what to do for IMAPParseUnexpectedEnd, Error or Timeout"
-(NSString *) copyTokensUpToNext: (char *)stopChars  {
    // only called when i indexes non space character
    
    self.result = IMAPParsing;
    NSString *tokenString = nil;
    
    NSUInteger rangeStart = self.currentCharLocation;
    NSUInteger rangeLength = 0;
    
    while (strchr(stopChars, self.currentByte) == NULL && (self.currentByte != 0) && ((self.result == IMAPParsing) || (self.result == IMAPParseWaiting))) {
        if ([self incrementBytePosition] != 0) self.result = IMAPParseUnexpectedEnd;
    };
    
    // If stop char, we want to leave the stop char
    // but if the stop char is the last character move the currentChar to the end
    // if the end, leave the currentChar at the end
    
    // if ccp == length at end : ccp
    // if ccp == length-1 found a stopChar and remove it : ccp++
    // if ccp < length-1 found a stopChar and leave it : ccp--
    
    if (strchr(stopChars,self.currentByte) != NULL) {
        // found stop char
        // do not include stop char in range
        //[self decrementBytePosition];
        //rangeLength = self.currentCharPosition - rangeStart;
    } else {
        //rangeLength = self.currentCharPosition - rangeStart;
        DDLogVerbose(@"Did not find stop char but ended anyhow! Check for IMAPParseUnexpectedEnd, Error or Timeout");
    }
    
    rangeLength = self.currentCharLocation - rangeStart;
    
    NSRange tokenRange = NSMakeRange(rangeStart, rangeLength);
    
    tokenString = [self copySubTokenStringWithRange: tokenRange];
    
    return tokenString;
}

-(NSString *) copySubTokenStringWithRange: (NSRange) tokenRange {
    self.result = IMAPParsing;
    NSString *tokenString = nil;
    
    // Timeout loop here
    NSDate *now = [NSDate date];
    
    while (([now timeIntervalSinceNow] > self.timeOutPeriod) && ((self.result == IMAPParsing) || (self.result == IMAPParseWaiting)) && [self.currentBuffer length] < (tokenRange.location+tokenRange.length)) {
        self.result = IMAPParseWaiting;
        if ([self.dataBuffers count]>1) {
            [self.currentBuffer appendData: (self.dataBuffers)[1]];
            [self.dataBuffers removeObjectAtIndex: 1];
            if ([self.currentBuffer length] >= (tokenRange.location+tokenRange.length)) {
                // we have enough data for current desired range
                self.result = IMAPParsing;
            }
        } else {
            
            // time interval is increasing negative
            @autoreleasepool {
                NSDate* loopInterval = [NSDate dateWithTimeIntervalSinceNow: kMBLOOPSECONDS];
                [[NSRunLoop currentRunLoop] runUntilDate: loopInterval];
            }
        }
    }
    
    if (([now timeIntervalSinceNow] <= self.timeOutPeriod) && [self.currentBuffer length] < (tokenRange.location+tokenRange.length)) {
        self.result = IMAPParseTimeOut;
    }
    
    IMAPParseResult currentResult = self.result;
    if ( (currentResult == IMAPParsing) || (currentResult == IMAPParseWaiting) ) {
        tokenString = [[NSString alloc] initWithData: [self.currentBuffer subdataWithRange: tokenRange] encoding: NSASCIIStringEncoding];
    }
    return tokenString;
}


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

-(void) performResponseMethodSelector: (SEL) commandSelector {
    
    if ([self respondsToSelector: commandSelector]) {
        [self performSelector: commandSelector ];
    } else {
        [self performSelector: NSSelectorFromString(@"responseUnknown")];
    }
}
-(void) performResponseMethodSelector: (SEL) commandSelector withArg: (id) arg {
    
    if ([self respondsToSelector: commandSelector]) {
        [self performSelector: commandSelector withObject: arg];
    } else {
        [self performSelector: NSSelectorFromString(@"responseUnknown")];
    }
}

#pragma clang diagnostic pop


@end

