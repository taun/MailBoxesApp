//
//  IMAPResponseBuffer.m
//  MailBoxes
//
//  Created by Taun Chapman on 8/18/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import "IMAPResponseBuffer.h"
#import "IMAPResponse.h"
#import "IMAPCommand.h"
#import "IMAPCoreDataStore.h"

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;


@interface IMAPResponseBuffer ()

-(void) clearParsedData;
@end

@implementation IMAPResponseBuffer

#pragma mark - initialization and dealloc
@synthesize dataBuffers;
@synthesize currentBuffer;
@synthesize currentByte = _currentByte;
@synthesize currentCharLocation;

@synthesize state;
@synthesize result;
@synthesize isTagged;
@synthesize hasLiteral;
@synthesize command;
@synthesize error;
@synthesize timeOutPeriod;
@synthesize clientStore;


- (NSString *) description {
    NSString *formattedDescription;
    formattedDescription = [NSString stringWithFormat: @"%@: dataBuffers: %lu, Position: %lu", 
                            [self className], (unsigned long)[dataBuffers count], currentCharLocation];
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

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        dataBuffers = [[NSMutableArray alloc] initWithCapacity: 2];
        currentBuffer = nil;
        currentCharLocation = 0;
        _currentByte = 0;
        
        isTagged = NO;
        hasLiteral = NO;
        command = nil;
        _delegate = nil;
        error = nil;
        
        state = 1;
        result = 0;

        timeOutPeriod = -2; //seconds
        
    }
    return self;
}

- (id <IMAPResponseDelegate>)delegate {
    return _delegate;
}

- (void)setDelegate:(id <IMAPResponseDelegate>)newDelegate {
    assert([newDelegate conformsToProtocol:@protocol(IMAPResponseDelegate)]);
    _delegate = newDelegate;
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
        self.currentBuffer = [self.dataBuffers objectAtIndex: 0];
        [self resetCurrentCharLocation];
    } else {
        // appending buffer to be used later
        [self.dataBuffers addObject: newDataBuffer];
    }
}

#pragma mark - main method
-(IMAPParseResult) parseBuffer: (IMAPResponse* __autoreleasing *)responseAddress {
    
    self.result = IMAPParseError;

    IMAPResponse* newResponse = nil;
    if (*responseAddress==nil) {
        newResponse = [[IMAPResponse alloc] init];
    }    
    
    if (newResponse != nil) {
        NSMutableArray *returnedTokens;
        NSString       *returnedString;
        
        self.result = IMAPParsing;
        
        [newResponse setDelegate: [self delegate]];
        [newResponse setClientStore: self.clientStore];
        [newResponse setCommand: self.command];

        while ( (self.currentByte != 0) && (self.result == IMAPParsing)) {
            //
            
            if (self.currentByte == '[') {
                // get all in brackets
                if ([self incrementBytePosition] == 0) {
                    returnedTokens = [self copyArrayTokensTo: ']'];
                    [newResponse.tokens addObject: returnedTokens];
                } else {
                    self.result = IMAPParseUnexpectedEnd;
                }
                
            } else if (self.currentByte == '(') {
                // recurse parenthesis
                if ([self incrementBytePosition] == 0) {
                    returnedTokens = [self copyArrayTokensTo: ')'];
                    [newResponse.tokens addObject: returnedTokens];
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
                        NSString *literalString = [[NSString alloc] initWithData: [self.currentBuffer subdataWithRange: literalRange] encoding: NSASCIIStringEncoding];
                        [newResponse.tokens addObject: literalString];
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
                    [newResponse.tokens addObject: returnedString];
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
                    [newResponse.tokens addObject: returnedString];
                }
                
            } else if (self.currentByte == ' ') {
                if ([self incrementBytePosition] != 0) {
                    self.result = IMAPParseUnexpectedEnd;                
                }
            }
        }
        
        [self clearParsedData];
        *responseAddress = newResponse;
    }
    
    return self.result;
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
            [self.currentBuffer appendData: [self.dataBuffers objectAtIndex: 1]];
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
                    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
                    // check for new buffer avail
                    if ([self.dataBuffers count] > 1) {
                        [self.currentBuffer appendData: [self.dataBuffers objectAtIndex: 1]];
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
    
    [self cacheCurrentByte];
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
    
    while ( (self.result == IMAPParsing) && (self.currentByte != stopChar) && (self.currentByte != 0)) {
        
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
//TODO: what to do for IMAPParseUnexpectedEnd, Error or Timeout
-(NSString *) copyTokensUpToNext: (char *)stopChars  {
    // only called when i indexes non space character
    
    self.result = IMAPParsing;
    NSString *tokenString = nil;
    
    NSUInteger rangeStart = self.currentCharLocation;
    NSUInteger rangeLength = 0;
    
    do {
        if ([self incrementBytePosition] != 0) {
            self.result = IMAPParseUnexpectedEnd;
        };
    } while (strchr(stopChars, self.currentByte) == NULL && (self.currentByte != 0) && ((result == IMAPParsing) || (result == IMAPParseWaiting)));
    
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
    
    while ( (self.result!=IMAPParseTimeOut) && [self.currentBuffer length] < (tokenRange.location+tokenRange.length)) {
        if ([self.dataBuffers count]>1) {
            [self.currentBuffer appendData: [self.dataBuffers objectAtIndex: 1]];
            [self.dataBuffers removeObjectAtIndex: 1];
        } else {
            // wait for more data or timeout
            self.result = IMAPParseTimeOut;
        }
    }
    if (self.result!=IMAPParseTimeOut) {
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



//-(void) performClientStoreMethodSelector: (SEL) commandSelector {
//    
//    if ([[self clientStore] respondsToSelector: commandSelector]) {
//        [[self clientStore] performSelector: commandSelector withObject: self];
//    } else {
//        [[self delegate] performSelector: NSSelectorFromString(@"responseUnknown") withObject: self];
//    }
//}
//
//-(void) performClientStoreMessageMethodFromToken: (NSString *) commandToken {
//    NSString *clientStoreCommand = [NSString stringWithFormat: @"setMessage%@:", [self normalizeToken: commandToken]];
//    [self performClientStoreMethodSelector: NSSelectorFromString(clientStoreCommand)];
//}

//-(void) performClientStoreMailBoxMethodFromToken: (NSString *) commandToken {
//    NSString *clientStoreCommand = [NSString stringWithFormat: @"setMailBox%@:", [self normalizeToken: commandToken]];
//    [self performClientStoreMethodSelector: NSSelectorFromString(clientStoreCommand)];
//}



@end

