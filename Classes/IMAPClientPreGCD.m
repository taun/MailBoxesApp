//
//  IMAPClient.m
//  MailBoxes
//
//  Created by Taun Chapman on 8/8/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import "IMAPClient.h"
#import "IMAPCommand.h"
#import "IMAPClientStoreControl.h"
#import "MBAccount+IMAP.h"
#import "MBox+IMAP.h"
#import "MBMessage+IMAP.h"
#import "MailBoxesAppDelegate.h"

#import "GCDAsyncSocket.h"

/*
 _commandResponseTable = [NSDictionary dictionaryWithObjectsAndKeys:
 [NSSet setWithObjects: @"FETCH", @"OK", @"NO", @"BAD", nil],                        @"FETCH",
 [NSSet setWithObjects: @"SEARCH", @"OK", @"NO", @"BAD", nil],                       @"SEARCH",
 [NSSet setWithObjects: @"FLAGS", @"EXISTS", @"RECENT", @"OK", @"NO", @"BAD", nil],  @"SELECT",
 [NSSet setWithObjects: @"FLAGS", @"EXISTS", @"RECENT", @"OK", @"NO", @"BAD", nil],  @"EXAMINE",
 [NSSet setWithObjects: @"LIST", @"OK", @"NO", @"BAD", nil],                         @"LIST",
 [NSSet setWithObjects: @"LIST", @"OK", @"NO", @"BAD", nil],                         @"RLIST",
 [NSSet setWithObjects: @"LSUB", @"OK", @"NO", @"BAD", nil],                         @"LSUB",
 [NSSet setWithObjects: @"LSUB", @"OK", @"NO", @"BAD", nil],                         @"RLSUB",
 [NSSet setWithObjects: @"STATUS", nil],                                             @"STATUS",
 [NSSet setWithObjects: @"EXPUNGE", @"OK", @"NO", @"BAD", nil],                       @"EXPUNGE",
 [NSSet setWithObjects: @"FETCH", @"OK", @"NO", @"BAD", nil],                        @"STORE",
 [NSSet setWithObjects: @"FETCH", @"SEARCH", @"OK", @"NO", @"BAD", nil],             @"UID",
 [NSSet setWithObjects: @"CAPABILITY", @"OK", @"BAD", nil],                          @"CAPABILITY",
 [NSSet setWithObjects: @"FETCH", nil],                                              @"STORE",
 [NSSet setWithObjects: @"BYE", @"OK", @"BAD", nil],                                 @"LOGOUT",
 [NSSet setWithObjects: @"OK", @"NO", @"BAD", nil],                                  @"CLOSE",
 [NSSet setWithObjects: @"OK", @"NO", nil],                                          @"CHECK",
 [NSSet setWithObjects: @"OK", @"NO", @"BAD", nil],                                  @"APPEND",
 [NSSet setWithObjects: @"OK", @"NO", @"BAD", nil],                                  @"SUBSCRIBE",
 [NSSet setWithObjects: @"OK", @"NO", @"BAD", nil],                                  @"RENAME",
 [NSSet setWithObjects: @"OK", @"NO", @"BAD", nil],                                  @"DELETE",
 [NSSet setWithObjects: @"OK", @"NO", @"BAD", nil],                                  @"CREATE",
 [NSSet setWithObjects: @"OK", @"NO", @"BAD", nil],                                  @"LOGIN",
 [NSSet setWithObjects: @"OK", @"NO", @"BAD", nil],                                  @"AUTHENTICATE",
 [NSSet setWithObjects: @"OK", @"BAD", nil],                                         @"NOOP",
 nil];

 */

/*!
 
 Private functions
 
 At some point many will need to be move public.
 
 */
@interface IMAPClient () 
@property (nonatomic, assign, readwrite) BOOL                   isFinished;
@property (nonatomic, assign, readwrite) BOOL                   isExecuting;
@property (nonatomic, assign, readwrite) BOOL                   isCommandComplete;
@property (nonatomic, assign, readwrite) UInt32                 commandIdentifier;

-(void) iStreamHasBytesAvailable: (NSStream *)theStream;
-(void) streamEndEncountered: (NSStream *)theStream ;
-(void) oStreamHasSpaceAvailable: (NSStream *)theStream;
-(void) streamErrorOccurred: (NSStream *)theStream;
-(void) streamOpenCompleted: (NSStream *)theStream;
-(void) streamEventNone: (NSStream *)theStream;
-(void) close: (NSStream*) theStream;
-(void) closeStreams;


-(void) sendCommand: (NSString*) aString;


//-(NSString *) 



// utility methods
-(NSString*) commandTag;
-(NSString*) nextCommandTag;
-(NSString*) formatCommandToken: (NSString*) aCommandString;
-(BOOL) hasCapability: (NSString*) capability;


// Sync methods
-(void) lightWeightSync;

@end

/*!
 At some point, the Ping.m code should be converted to NSStream and integrated into
 a Superclass of IMAPClient. This would enable testing of the network connection before
 attempting to connect. Is it possible to test if there is even a network adapter
 available before trying the network connection?
 */

@implementation IMAPClient

#pragma mark - init and cleanup
@synthesize clientStore;

@synthesize eventHandlers = _eventHandlers;

@synthesize isFinished = _finished;
@synthesize isCancelled = _cancelled;
@synthesize isExecuting;

@synthesize dataBuffer = _dataBuffer;
@synthesize dataBufferRemainingBytes;
@synthesize isBufferUpdated = _bufferUpdated;
@synthesize isBufferComplete;
@synthesize isSpaceAvailable = _spaceAvailable;

@synthesize parser;

@synthesize connectionState;
@synthesize connectionTimeOutSeconds;
@synthesize isConnectionTimedOut;

@synthesize commandIdentifier;
@synthesize isCommandComplete;

@synthesize serverCapabilities;
@synthesize timeOutPeriod;
@synthesize runLoopInterval;

@synthesize syncQuantaF;
@synthesize syncQuantaLW;

@synthesize mboxSequenceUIDMap;
@synthesize mainCommandQueue;

- (id)initWithAccount: (NSManagedObjectID *) anAccountID
{
    assert(anAccountID != nil);

    self = [super init];
    if (self) {
        // Initialization code here.
        
        _cancelled = NO;
        _finished = NO;
        isExecuting = NO;
        connectionState = IMAPDisconnected;
        connectionTimeOutSeconds = 120;
        isConnectionTimedOut = NO;

        _dataBuffer = [[NSMutableArray alloc] initWithCapacity: 4];
        _bufferUpdated = NO;
        isBufferComplete = YES;
        _spaceAvailable = NO;
        
        _eventHandlers = [NSDictionary dictionaryWithObjectsAndKeys:
                         @"iStreamHasBytesAvailable:",[NSNumber numberWithInt:NSStreamEventHasBytesAvailable] , 
                         @"streamEndEncountered:",[NSNumber numberWithInt:NSStreamEventEndEncountered] ,  
                         @"oStreamHasSpaceAvailable:",[NSNumber numberWithInt:NSStreamEventHasSpaceAvailable] ,  
                         @"streamErrorOccurred:",[NSNumber numberWithInt:NSStreamEventErrorOccurred] ,  
                         @"streamOpenCompleted:",[NSNumber numberWithInt:NSStreamEventOpenCompleted] ,
                         @"streamEventNone:",[NSNumber numberWithInt:NSStreamEventNone] , 
                          nil];
        
        commandIdentifier = 0;
        
        serverCapabilities = [[NSMutableSet alloc] initWithCapacity: 5] ;
        
        clientStore = [[IMAPClientStoreControl alloc] initWithAccount: anAccountID];
        
        parser = [[IMAPResponseParser alloc] init];
        parser.delegate = self;
        parser.timeOutPeriod = -1; // incoming timeout
        timeOutPeriod = -2; // outgoing timeout
        runLoopInterval = 0.01; // seconds
        parser.clientStore = self.clientStore;
        
        
        syncQuantaLW = 250;
        syncQuantaF = 20;
        
        mboxSequenceUIDMap = [[NSMutableDictionary alloc] initWithCapacity:10];
        mainCommandQueue = [[NSMutableArray alloc] initWithCapacity: 2];
    }
    
    return self;
}

-(id) init {
    return [self initWithAccount: nil];
}



#pragma mark - Stream Event Handling
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    NSString* eventHandler = [self.eventHandlers objectForKey: [NSNumber numberWithInt: streamEvent] ];
    if([self respondsToSelector:NSSelectorFromString(eventHandler)]){
        [self performSelector:NSSelectorFromString(eventHandler)
                   withObject: theStream];
    }else{
        DDLogError(@"%@: No stream event handler.", NSStringFromClass([self class]));
    }
}
#pragma clang diagnostic pop

-(void) streamEventNone: (NSStream *)theStream {
    DDLogVerbose(@"%@: streamEventNone.", NSStringFromClass([self class]));
    
}
-(void) streamOpenCompleted: (NSStream *)theStream {
    if(theStream == _iStream){
        self.connectionState = IMAPGreeting;
        //[self getResponse];
    }else{
        if (self.connectionState == IMAPNewConnection) {
            self.connectionState = IMAPEstablished;
        }
    }
    //DDLogVerbose(@"%@: streamOpenCompleted.", NSStringFromClass([self class]));
}
-(void) iStreamHasBytesAvailable: (NSStream *)theStream {
    // iStream has input
    //DDLogVerbose(@"%@: iStreamHasBytesAvailable.", NSStringFromClass([self class]));
    [self getResponse];
}
-(void) oStreamHasSpaceAvailable: (NSStream *)theStream {
    self.isSpaceAvailable = YES;
    //DDLogVerbose(@"%@: oStreamHasSpaceAvailable.", NSStringFromClass([self class]));
    
}
-(void) streamErrorOccurred: (NSStream *)theStream {
    NSError *theError = [theStream streamError];
    //DDLogVerbose(@"Error reading stream!%@",[NSString stringWithFormat:@"Error %i: %@",
    //                                  [theError code], [theError localizedDescription]]);
    [self close: theStream];
}
-(void) streamEndEncountered: (NSStream *)theStream {
    //DDLogVerbose(@"%@: streamEndEncountered.", NSStringFromClass([self class]));
    [self close: theStream];
}

#pragma  mark - stream i/o
/*!
 convert command string to proper format and transmit to the server.
 */
-(void) sendCommand: (NSString*) aString {
    NSData * dataToSend = [aString dataUsingEncoding: NSASCIIStringEncoding allowLossyConversion: YES];
    if (_oStream) {
        int remainingToWrite = [dataToSend length];
        void * marker = (void *)[dataToSend bytes];
        while (remainingToWrite > 0) {
            int actuallyWritten = 0;
            actuallyWritten = [(NSOutputStream*) _oStream write:marker maxLength:remainingToWrite];
            remainingToWrite -= actuallyWritten;
            marker += actuallyWritten;
        }
    }    
    DDLogVerbose(@"%@: Sent Command: %@.", NSStringFromClass([self class]), aString);
}

/*!
 any response line starting with "*" or a command identifier 
 store as a line on the stack.
 Check line for ending of "{###}"
 if found, store next ### characters on the stack
 
 "Second, mind the transition between literal and non-literal modes. You 
 are either outputting a line, which is set of octets terminated by CRLF; 
 or you are outputting a literal, which is a precisely counted number of 
 octets with no termination. However, in all cases in IMAP, there is a 
 line after a literal (even if it is just a CRLF to end the command or 
 response). 
 
 Some commands may have multiple literals. So, if a command has two 
 arguments, both of which come in as literals, you must: read line, read 
 sized buffer, read line, read sized buffer, read line. The SEARCH command 
 can have quite a few literals. Or it may have none. Be prepared. "
 http://mailman2.u.washington.edu/pipermail/imap-protocol/2011-June/001471.html
  
 */


// called asynchronously by streaming delegate methods
-(void) getResponse {
    // can this be interrupted by another asynchronous hasBytesAvailable call?
    // causing mutliple access to the same resource (buffers, stack)?
    
    // not all data may be available during this call. It may take multiple calls to get the full response.
    // In addition there may be a network outage and the data may never be complete.
    // need to fill an instance buffer async until complete then pass the instance buffer to IMAPResponse for synchronous parsing.
    
    NSInteger actuallyRead = 0;
    NSUInteger bufferSize = 4096;
    uint8_t buffer[bufferSize]; // static local buffer
    BOOL done = NO;
    
    
    actuallyRead = [(NSInputStream*) _iStream read:(uint8_t *)buffer maxLength: bufferSize];
    // don't need dataBuffer, using parser? 
    if (actuallyRead > 0) {
        NSMutableData *responseBuffer = [[NSMutableData alloc] initWithCapacity: actuallyRead]; // instance buffer
        
        [responseBuffer appendBytes: buffer length: actuallyRead];
        
        [self.parser addDataBuffer: responseBuffer];
        
    }
}



#pragma mark - methods to handle server responses

// called synchronously by loop extraction of response stack
//-(void) parseResponse { 
//    NSString *currentString = [parser copyStringFromCurrentBuffer];
//    DDLogVerbose(@"%@: parsing: %@", NSStringFromClass([self class]), currentString);
//    [currentString release];
//    
//    [parser parseResponse];
//    [parser evaluateResponse];
//}


-(void) commandDone: (IMAPResponseParser *) response {
    // response started with a tag
    NSError *saveError = nil;
    NSString *status = nil;
    BOOL success = NO;
    if ([self.parser.command.tag compare: [self.parser.tokens objectAtIndex: 0]] == NSOrderedSame) {
        // command tags are equal
        status = [self.parser.tokens objectAtIndex: 1];
        if ([status compare: @"OK"] == NSOrderedSame) {
            //
            success = [self.clientStore save: &saveError];
            self.parser.command.responseStatus = IMAPOK;
            
        } else if ([status compare: @"NO"] == NSOrderedSame) {
            //
            self.parser.command.responseStatus = IMAPNO;
        } else if ([status compare: @"BAD"] == NSOrderedSame) {
        //
            self.parser.command.responseStatus = IMAPBAD;
        } else if ([status compare: @"BYE"] == NSOrderedSame) {
            //
            self.parser.command.responseStatus = IMAPBYE;
        }
        self.parser.command.isDone = YES;
    }
    DDLogVerbose(@"%@:%@ command completed(%@): Save Status %i: tokens %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.parser.command.tag, success, self.parser.tokens);
}

-(void) commandContinue:(id)response {
    DDLogVerbose(@"%@: command continue(%@): %@", NSStringFromClass([self class]), self.parser.command.tag, self.parser.tokens);
}

#pragma mark - Response Delegate Methods

#pragma mark - Resp-text-codes
-(void) receivedCapability: (NSArray *) tokens {
    for ( id argument in tokens) {
        [self.serverCapabilities addObject: [argument uppercaseString]];
    }
}


//TODO: how to repopen streams later? Timer?
//TODO: set command complete to keep from blocking?
// or check for IMAPBYE in run loop?
-(void) receivedBye {
    [self closeStreams];
}
-(void) receivedUnknown {
    DDLogVerbose(@"%@: unknown response: %@", NSStringFromClass([self class]), self.parser.tokens);
}
-(void) receivedIgnore {
    DDLogVerbose(@"%@: ignoring response: %@", NSStringFromClass([self class]), self.parser.tokens);
}


#pragma mark - MailBox-Data responses

// TODO: how to determine whether a pre-existing folder has been deleted on the server while 
// offline? Same in reverse. A folder deleted on the client while offline needs to be deleted
// on the server side? Need a queue of offline commands executed to be replayed when online and 
// before regular sync.
// TODO: offline re-sync later.


-(void) responseLsub: (id) response{
    
}

-(void) responseSearch: (id) response{
    
}



#pragma mark - command streaming methods

-(NSString*) commandTag {
    return [NSString stringWithFormat:@"moedae%05hu", self.commandIdentifier];
}

-(NSString*) nextCommandTag {
    self.commandIdentifier += 1;
    return [self commandTag];
}


-(void) evaluateResponseAndWaitForCommandDone {
    NSDate *now = [NSDate date];
    @autoreleasepool {
        while (self.parser.command.isDone == NO && [now timeIntervalSinceNow] > (self.timeOutPeriod * 10)) {
            if ([self.parser.dataBuffers count] > 0) {
                IMAPParseResult result = [self.parser parseResponse];
                if (result == IMAPParseComplete) {
                    [self.parser evaluateResponse];
                    // isDone is set when commandDone is called by parser during evaluation
                }
            }
            if (self.parser.command.isDone == NO) {
                [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow: self.runLoopInterval]];
            }
        }

    }
}

-(void) submitCommand {
    self.parser.command.tag = [self nextCommandTag];
    NSString* commandString = (NSString*) [self.parser.command nextOutput];
    NSDate *now = [NSDate date];
    
    // time interval is increasing negative
    while (!self.isSpaceAvailable && [now timeIntervalSinceNow] > self.timeOutPeriod) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow: self.runLoopInterval]];
    }
    if (self.isSpaceAvailable) {
        [self sendCommand: commandString];
        self.parser.command.isActive = YES;
    }
}

#pragma mark - IMAP commands
/*!
 Compose command string
 submit command | tag command | add command to dictionary | send command
    wait in run loop for ready to send
        send
    wait in run loop for completion
 wait in runloop for responses to run to completion | commandDone or commandContinue ends runnLoop | remove command | return command
 Finish command tasks such as selected MailBox, release command
 */
-(void) commandCapability {
    IMAPCommand* command = [[IMAPCommand alloc] initWithAtom: @"CAPABILITY"];
    self.parser.command = command;
    [self submitCommand];
    if (self.parser.command.isActive == YES) {
        [self evaluateResponseAndWaitForCommandDone];
        // commandDone: will be called by parser then return to here
    } else {
        // TODO: handle command outgoing connection time out.
    }
}

-(void) commandNoop {
    IMAPCommand* command = [[IMAPCommand alloc] initWithAtom: @"NOOP"];
    self.parser.command = command;
    [self submitCommand];
    if (self.parser.command.isActive == YES) {
        [self evaluateResponseAndWaitForCommandDone];
        // commandDone: will be called by parser then return to here
    } else {
        // TODO: handle command outgoing connection time out.
    }
}

-(void) commandStartTLS{
    // unimplemented as unnecessary?
}

-(void) commandLogin {
    // Check for auth capabilities
    IMAPCommand* command = nil;
    if ([self hasCapability: @"AUTH=LOGIN"]) {
        command = [[IMAPCommand alloc] initWithAtom: @"login"];
        [command copyAddArgument: self.clientStore.account.username];
        [command copyAddArgument: self.clientStore.account.password];
        self.parser.command = command;
        [self submitCommand];
        if (self.parser.command.isActive == YES) {
            [self evaluateResponseAndWaitForCommandDone];
            // commandDone: will be called by parser then return to here
        } else {
            // TODO: handle command outgoing connection time out.
        }
    }
}

/*!
 USE XLIST if available
 Just simple behaviour for now.
 Add arguments in the future?
 Add default to xlist if it exists in capabilities?
 */
-(void) commandList {
    // Just always list the full directory structure
    if ([self hasCapability: @"XLIST"]) {
        [self commandXList];
    } else {
        IMAPCommand* command = [[IMAPCommand alloc] initWithAtom: @"LIST"];
        [command copyAddArgument: @"\"\""];
        [command copyAddArgument: @"*"];
        self.parser.command = command;
        [self submitCommand];
        if (self.parser.command.isActive == YES) {
            [self evaluateResponseAndWaitForCommandDone];
            // commandDone: will be called by parser then return to here
        } else {
            // TODO: handle command outgoing connection time out.
        }
    }
}

-(void) commandXList {
    // Just always list the full directory structure
    if ([self hasCapability: @"XLIST"]) {
        IMAPCommand* command = [[IMAPCommand alloc] initWithAtom: @"XLIST"];
        [command copyAddArgument: @"\"\""];
        [command copyAddArgument: @"*"];
        self.parser.command = command;
        [self submitCommand];
        if (self.parser.command.isActive == YES) {
            [self evaluateResponseAndWaitForCommandDone];
            // commandDone: will be called by parser then return to here
        } else {
            // TODO: handle command outgoing connection time out.
        }
    } else {
        [self commandList];
    }
}

/*!
 No need for this with core data structure?
 */
-(void) commandListExtended {
    
}

//TODO: how to let response know that the current command is for mbox arg?

/*!
 Arguments:  mailbox name
 status data item names
 Responses:  untagged responses: STATUS
 Result:     OK - status completed
 NO - status failure: no status for that name
 BAD - command unknown or arguments invalid
 
 The currently defined status data items that can be requested are:
 MESSAGES - The number of messages in the mailbox.
 RECENT - The number of messages with the \Recent flag set.
 UIDNEXT - The next unique identifier value of the mailbox.  Refer to
 section-  2.3.1.1 for more information.
 UIDVALIDITY - The unique identifier validity value of the mailbox.  Refer to
 section 2.3.1.1 for more information.
 UNSEEN - The number of messages which do not have the \Seen flag set.
 */
-(void) commandStatus: (MBox *) mbox {
    IMAPCommand* command = [[IMAPCommand alloc] initWithAtom: @"STATUS"];
    command.mbox = mbox;
    [command copyAddArgument: command.mbox.fullPath];
    [command copyAddArgument: @"(UIDVALIDITY"];
    [command copyAddArgument: @"MESSAGES"];
    [command copyAddArgument: @"UNSEEN)"];
    self.parser.command = command;
    [self submitCommand];
    if (self.parser.command.isActive == YES) {
        [self evaluateResponseAndWaitForCommandDone];
        // commandDone: will be called by parser then return to here
    } else {
        // TODO: handle command outgoing connection time out.
    }
}

//TODO: IDLE will not complete until "done" is sent. results in a continue state.
// need to handle continue state and send done before future commands.

/*!
 
 */
-(void) commandIdle {
    IMAPCommand* command = [[IMAPCommand alloc] initWithAtom: @"IDLE"];
    self.parser.command = command;
    [self submitCommand];
    if (self.parser.command.isActive == YES) {
        [self evaluateResponseAndWaitForCommandDone];
        // commandDone: will be called by parser then return to here
    } else {
        // TODO: handle command outgoing connection time out.
    }
    // change state?
    // commands need to check state and send done then wait for completion
    // before new command executes. Add to command class?
    //[self waitForCompletion];
    
}

//TODO: Check OK completion status before assigning selected mailbox.
-(void) commandSelect: (NSString *) mboxPath{    
    [self.clientStore selectMailBox: mboxPath];
    
    IMAPCommand* command = [[IMAPCommand alloc] initWithAtom: @"SELECT"];
    command.mboxFullPath =  mboxPath;
    [command copyAddArgument: mboxPath];
    
    self.parser.command = command;
    [self submitCommand];
    if (self.parser.command.isActive == YES) {
        [self evaluateResponseAndWaitForCommandDone];
        // commandDone: will be called by parser then return to here
        // check for status == OK here
    } else {
        // TODO: handle command outgoing connection time out.
    }
}

// CommandFetch must always include UID to enable proper response parsing!
// TODO: need to pass the message UID range
/*
 To fetch headers for initial sync -  "uid fetch uid1:uidN (envelope flags)"
 
 Need an different fetch command for the body and attachments and ???
 
 commandFetchHeadersFrom:to:
 commandFetchBodyStructureOf: uid fetch uidX bodystructure
 commandFetchBodyTextOf:    uid fetch uidX (body[text])
 
 uid fetch uidX body[] = full raw message
 
 uid fetch 100:110 (FLAGS BODYSTRUCTURE INTERNALDATE RFC822.SIZE ENVELOPE
 */
-(void) commandFetchLStart: (UInt64) startRange end: (UInt64) endRange {
    IMAPCommand* command = [[IMAPCommand alloc] initWithAtom: @"UID FETCH"];
    NSString *sequence = [NSString stringWithFormat: @"%lu:%lu", startRange, endRange];
    [command copyAddArgument: sequence];
    [command copyAddArgument: @"(FLAGS"];
    //[command copyAddArgument: @"INTERNALDATE"];
    [command copyAddArgument: @"RFC822.SIZE"];
    [command copyAddArgument: @"RFC822.HEADER)"];
    command.mboxFullPath = self.clientStore.selectedMBox.fullPath;
    self.parser.command = command;
    [self submitCommand];
    if (self.parser.command.isActive == YES) {
        [self evaluateResponseAndWaitForCommandDone];
        // commandDone: will be called by parser then return to here
        // check for status == OK here
    } else {
        // TODO: handle command outgoing connection time out.
    }
}

-(void) commandFetchFStart: (UInt64) startRange end: (UInt64) endRange {
    IMAPCommand* command = [[IMAPCommand alloc] initWithAtom: @"UID FETCH"];
    NSString *sequence = [NSString stringWithFormat: @"%lu:%lu", startRange, endRange];
    [command copyAddArgument: sequence];
    [command copyAddArgument: @"(FLAGS"];
    //[command copyAddArgument: @"INTERNALDATE"];
    [command copyAddArgument: @"RFC822.SIZE"];
    [command copyAddArgument: @"RFC822.HEADER)"];
    command.mboxFullPath = self.clientStore.selectedMBox.fullPath;
    self.parser.command = command;
    [self submitCommand];
    if (self.parser.command.isActive == YES) {
        [self evaluateResponseAndWaitForCommandDone];
        // commandDone: will be called by parser then return to here
        // check for status == OK here
    } else {
        // TODO: handle command outgoing connection time out.
    }
}

-(void) commandLogout {
    
}

-(void) commandAuthenticate {
    
}

-(void) commandExamine:(MBox *)mbox {
    
}

-(void) commandCreate:(MBox *)mbox {
    
}

-(void) commandDelete:(MBox *)mbox {
    
}

-(void) commandRename:(MBox *)mbox to:(NSString *)newName {
    
}

-(void) commandSubscribe:(MBox *)mbox {
    
}

-(void) commandUnSubscribe:(MBox *)mbox {
    
}

-(void) commandLsub {
    
}

-(void) commandAppend:(MBox *)mbox {
    
}

-(void) commandCheck {
    
}

-(void) commandClose {
    
}

-(void) commandExpunge {
    
}

-(void) commandSearch {
    
}

-(void) commandFetch {
    
}


-(void) commandStore {
    
}

-(void) commandCopy {
    
}

-(void) commandUid {
    
}


#pragma mark - command and response utility methods

//-(NSString *) commandTag {
//    return [NSString stringWithFormat:@"moedae%05hu", self.commandIdentifier];
//}
//
//-(NSString *) nextCommandTag {
//    self.commandIdentifier += 1;
//    return [self commandTag];
//}
//
//
//-(void) waitForCompletion {
//    [self sendNextCommand];
//    while (! self.isCommandComplete) {
//        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
//        if ([self.parser.dataBuffers count] >0) {
//            IMAPParseResult result = [self.parser parseResponse];
//            if (result == IMAPParseComplete) {
//                [self.parser evaluateResponse];
//            }
//        }
//    }
//}
//
//-(void) pushCommand:(IMAPCommand*)aCommand {
//    [self.commandStack addObject: aCommand];
//}
//
//-(id) currentCommand {
//    id command = [self.commandStack objectAtIndex:0];
//    
//    return command;
//}
//
//-(id) copyPopCommand {
//    id command = [[self.commandStack objectAtIndex:0] retain];
//    [self.commandStack removeObjectAtIndex: 0];
//    
//    return command;
//}
//
//-(void) pushResponse:(id)aResponse {
//    [self.responseStack addObject: aResponse];
//}
//
//-(id) currentResponse {
//    id response = [self.responseStack objectAtIndex:0];
//    
//    return response;
//}
//
//-(id) copyPopResponse {
//    id response = [[self.responseStack objectAtIndex:0] retain];
//    [self.responseStack removeObjectAtIndex: 0];
//    
//    return response;
//}

/*! 
 checks for the existence of the method before dispatching
 */
//-(void) performResponseCommand: (SEL) commandSelector withObject: (id) anArg {
//    
//    if ([self respondsToSelector: commandSelector]) {
//        [self performSelector: commandSelector withObject: anArg];
//    } else {
//        [self responseUnknown: anArg];
//    }
//}
//-(void) performResponseCommand: (SEL) commandSelector withObject: (id) anArg1 withObject:(id)anArg2 {
//    
//    if ([self respondsToSelector: commandSelector]) {
//        [self performSelector: commandSelector withObject: anArg1 withObject: anArg2];
//    } else {
//        [self responseUnknown: anArg1];
//    }
//}

/*!
 convenience method to reformat the command method tokens
 */
-(NSString*) formatCommandToken:(NSString *)aCommandString {
    
    NSString* formattedCommand = [[aCommandString stringByTrimmingCharactersInSet:
                                   [NSCharacterSet whitespaceCharacterSet]] 
                                  capitalizedString];
    
    NSMutableString* reFormattedCommand = [NSMutableString stringWithString: formattedCommand];
    
    [reFormattedCommand replaceOccurrencesOfString:@"-" 
                                        withString:@"" 
                                           options: NSCaseInsensitiveSearch 
                                             range:NSMakeRange(0, [formattedCommand length])];
    return reFormattedCommand;
}

/*! 
 convenience method to make it easy to check for a server capability
 */
-(BOOL) hasCapability:(NSString *)capability {
    return [self.serverCapabilities containsObject: capability];
}


#pragma mark - IMAP Sync methods

// TODO: create regex for ip6
-(BOOL) openConnection: (NSError**) anError {    
    NSError* regexError = nil;
    SEL hostSelector;
    
    NSString *server = self.clientStore.account.server;
    
    if (![server isEqualToString:@""]) {
        
        // TODO: create regex for ip6
        // selector hostWithName: vs hostWithAddress:
        // 127.0.0.1 regex is \d{1,3}[.]\d{1,3}[.]\d{1,3}[.]\d{1,3}
        NSRegularExpression* ip4AddressPattern;
        ip4AddressPattern = [NSRegularExpression
                                 regularExpressionWithPattern: @"\\d{1,3}[.]\\d{1,3}[.]\\d{1,3}[.]\\d{1,3}"
                                 options: NSRegularExpressionCaseInsensitive
                                 error: &regexError];

        NSUInteger numberOfMatches = [ip4AddressPattern numberOfMatchesInString: server
                                                                       options:0
                                                                         range:NSMakeRange(0, [server length])];
        NSHost *host;
        if (numberOfMatches==1) {
            host = [NSHost hostWithAddress:server];
        }else{
            host = [NSHost hostWithName:server];
        }

        NSString* address = [host address];
        if (address) {
            //DDLogVerbose(@"%@: %@ resolved to address %@", NSStringFromClass([self class]), server, address);

            NSInputStream *tempIStream;
            NSOutputStream *tempOStream;
            
            [NSStream getStreamsToHost:host 
                                  port: [self.clientStore.account.port intValue] 
                           inputStream:&tempIStream
                          outputStream:&tempOStream];
            
            _iStream = tempIStream;
            _oStream = tempOStream;
            
            [_iStream setDelegate:self];
            [_oStream setDelegate:self];
            
            [_iStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                forMode:NSDefaultRunLoopMode];
            [_oStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                forMode:NSDefaultRunLoopMode];
            [_iStream open];
            [_oStream open];
            //DDLogVerbose(@"%@: IO Streams opening.", NSStringFromClass([self class]));
            //[self send:@"helo"];
            //wait for initial response
            NSDate* started = [NSDate date];
            NSTimeInterval netConnectTimeout = 30.0;
            
            while ([self.parser.dataBuffers count]==0) {
                // TODO: need to set a connection timeout here
                [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow: self.runLoopInterval]];
                
                if ([started timeIntervalSinceNow] > netConnectTimeout) {
                    // timed out. need to pass and error?
                    DDLogVerbose(@"%@: Response timed out (%@ sec) for: %@.", 
                          NSStringFromClass([self class]), netConnectTimeout, server);
                    
                    return NO;
                }
            }
            [self commandCapability];
            [self commandLogin];
            return YES;
        }
        else {
            DDLogVerbose(@"%@: No address resolution for: %@.", NSStringFromClass([self class]), server);
            return NO;
        }
    }
    return NO;
}

-(void) close: (NSStream*) aStream{
    [aStream close];
    [aStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [aStream setDelegate:nil];
    aStream = nil;
}

-(void) closeStreams {
    [self close:_iStream];
    [self close:_oStream];
    self.connectionState = IMAPDisconnected;
    DDLogVerbose(@"%@: Streams closed.", NSStringFromClass([self class]));
}

//TODO: error handling if we can't save the context.
// how to recover? how to inform?
/*!
 Sync the current selected mailbox with just the vital information.
 Information useful for the model and for showing the GUI message listing
 Items
    UID
    Sequence
    From: 
    To:
    Subject:
    Internal Date:
    RFC2822 Size
    
    Start from latest and work back in groups
    sample command> uid fetch 100:110 (FLAGS BODYSTRUCTURE INTERNALDATE RFC822.SIZE ENVELOPE
 
    set mboxSequenceUIDMap for mailboxes during lightweight sync
 
 
 50 minutes for 12500 headers
 12500/50 = 250 headers/minute, 4 headers/sec
 
 */
-(void) lightWeightSync {
    BOOL saveSuccess;
    NSError *saveError = nil;

    //saveSuccess = [self.clientStore selectedMailBoxDeleteAllMessages: &saveError];
    saveSuccess = YES;
    
    
    
    if (saveSuccess) {
        
        
        UInt64 uidNext;
        UInt64 maxFillUid;

        NSNumber* lowestUID = [self.clientStore getLowestUID];
        DDLogVerbose(@"lowestUID %@", lowestUID);
        
        if (lowestUID == nil || [lowestUID unsignedLongLongValue] == 0) {
            // lowestUID was not found meaning cache is empty?
            // once there is a pre-fetch on load, there should never be 0
            maxFillUid = [self.clientStore.selectedMBox.serverUIDNext unsignedLongLongValue];
        } else {
            maxFillUid = [lowestUID unsignedLongLongValue];
        }
        DDLogVerbose(@"lowestUID %hu", maxFillUid);
        
        UInt64 endRange = maxFillUid;
        //UInt64 endRange = totalRange + 1;
        //UInt64 endRange = 200; // override for testing
        UInt64 startRange = 0;
        BOOL isFinished = NO;        
        while (!self.isFinished && !self.isCancelled) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow: self.runLoopInterval]];
            @autoreleasepool {
                if (endRange > self.syncQuantaLW) {
                    startRange = endRange - self.syncQuantaLW;
                } else {
                    startRange = 1;
                    self.isFinished = YES;
                }
                [self commandFetchLStart: startRange end: endRange];
                saveSuccess = [self.clientStore save: &saveError];
                if (saveSuccess) {
                    endRange -= self.syncQuantaLW;
                } else {
                    // don't bother continuing if we can't save
                    self.isFinished = YES;
                }
            }
        }
    }
}

#pragma mark - High level App Methods
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

-(void) refreshAll {
    self.isCancelled = NO;
    self.isFinished = NO;
    self.isExecuting = YES;
    self.isCommandComplete = YES;
    
    NSError* error = nil;
    BOOL connected;
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter]; 
    
    @try {
        @autoreleasepool {
            connected = [self openConnection: &error];
            if (connected) {
                // do some work process an event?
                
                [self commandList];
                
                [self commandSelect: @"INBOX"];
                [self lightWeightSync];
                
                while (!self.isFinished && !self.isCancelled) {
                    // wait for and parse responses until cancelled
                    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow: self.runLoopInterval]];
                    
                    if([self.parser.dataBuffers count] > 0 ){
                        // parser dataBuffers fill asynchronously
                        IMAPParseResult result = [self.parser parseResponse];
                        
                        if (result == IMAPParseComplete) {
                            [self.parser evaluateResponse];
                        }
                    }
                    if ([self.mainCommandQueue count] > 0) {
                        NSArray* command = [self.mainCommandQueue objectAtIndex: 0];
                        [self.mainCommandQueue removeObjectAtIndex: 0];
                        [self performSelector: NSSelectorFromString([command objectAtIndex:0]) withObject: [command objectAtIndex: 1]];
                    }
                }
            }
            else {
                // parse connection error
                DDLogVerbose(@"%@: Streams connection error: %@.", NSStringFromClass([self class]), error);
                
                while (!self.isCancelled) {
                    // do nothing
                    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow: self.runLoopInterval]];
                }
            }
            
        }
    }
    @catch (NSException *exception) {
        self.isExecuting = NO;

        NSString *exceptionMessage = [NSString stringWithFormat:@"%@\nReason: %@\nUser Info: %@", [exception name], [exception reason], [exception userInfo]];
        // Always log to console for history
        DDLogVerbose(@"Exception raised:\n%@", exceptionMessage);
        DDLogVerbose(@"Backtrace: %@", [exception callStackSymbols]);
    }
    @finally {
        self.isExecuting = NO;
        [self closeStreams];
        self.isFinished = YES;
    }
}

#pragma clang diagnostic pop

/*!
 Need to fetch the message based on the message objectID.
 Get the message mail box.
 IMAP SELECT the mail box
 IMAP FETCH the full message 
 When IMAP response is finished, return.
 */
-(void) loadFullMessage: (NSManagedObjectID*) objectID {
    self.isCancelled = NO;
    self.isFinished = NO;
    self.isCommandComplete = YES;
    
    NSError* error = nil;
    BOOL connected;
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter]; 
    
    @try {
        
        connected = [self openConnection: &error];
        if (connected) {
            // do some work process an event?
            MBMessage* message = [self.clientStore messageForObjectID: objectID];
            MBox* mbox = message.mbox;
            
            UInt64 muid = [message.uid longLongValue];

            [self commandSelect: mbox.fullPath];
            [self commandFetchFStart: muid end: muid];
            
            while (!self.isFinished && !self.isCancelled) {
                // wait for and parse responses until cancelled
                [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow: self.runLoopInterval]];
                
                if([self.parser.dataBuffers count] > 0 ){
                    // parser dataBuffers fill asynchronously
                    IMAPParseResult result = [self.parser parseResponse];
                    
                    if (result == IMAPParseComplete) {
                        [self.parser evaluateResponse];
                    }
                }
            }
        }
        else {
            // parse connection error
            DDLogVerbose(@"%@: Streams connection error: %@.", NSStringFromClass([self class]), error);
            
            while (!self.isCancelled) {
                // do nothing
                [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow: self.runLoopInterval]];
            }
        }
        
    }
    @catch (NSException *exception) {
        NSString *exceptionMessage = [NSString stringWithFormat:@"%@\nReason: %@\nUser Info: %@", [exception name], [exception reason], [exception userInfo]];
        // Always log to console for history
        DDLogVerbose(@"Exception raised:\n%@", exceptionMessage);
        DDLogVerbose(@"Backtrace: %@", [exception callStackSymbols]);
    }
    @finally {
        [self closeStreams];
        self.isFinished = YES;
    }
}

-(void) testMessage:(NSString *)aMessage {
    DDLogVerbose(@"Testing Account name: %@", self.clientStore.account.name);
    DDLogVerbose(@"Just testing, passed: %@", aMessage);
}

@end