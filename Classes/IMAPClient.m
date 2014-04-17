//
//  IMAPClient.m
//  MailBoxes
//
//  Created by Taun Chapman on 8/8/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import "GCDAsyncSocket.h"

#import "IMAPClient.h"
#import "IMAPCommand.h"
#import "IMAPCoreDataStore.h"

#import "MBAccount+IMAP.h"
#import "MBox+IMAP.h"
#import "MBMessage+IMAP.h"
#import "MBMime+IMAP.h"

#import "IMAPParsedResponse.h"
//#import "GCDAsyncSocket.h"

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;


/*!
 ## Internal IMAPClient implementation details
 
 All of the IMAPClient related classes make extensive use of a method dispatch pattern based on adding a set prefix to the desired command or
 response and dispatching to that method for handling of the command or response. The code handling the dispatch is unaware of what command
 or response is being handled. If a command or response is unimplemented, the dispatch will be to a default method for unhandled commands and
 responses. This means the process of implementing the handling of a new response involves adding a method with the appropriate name which can
 handle the response values.
 
 ### Command Response Table
 
 <pre>
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
 </pre>
 
 
 ### SSL Transport errors
 
 <pre>
 Result Code,Value,Description
 errSSLProtocol,–9800,"SSL protocol error.\nAvailable in OS X v10.2 and later."
 errSSLNegotiation,–9801,"The cipher suite negotiation failed.\nAvailable in OS X v10.2 and later."
 errSSLFatalAlert,–9802,"A fatal alert was encountered.\nAvailable in OS X v10.2 and later."
 errSSLWouldBlock,–9803,"Function is blocked; waiting for I/O. This is not fatal.\nAvailable in OS X v10.2 and later."
 errSSLSessionNotFound,–9804,"An attempt to restore an unknown session failed.\nAvailable in OS X v10.2 and later."
 errSSLClosedGraceful,–9805,"The connection closed gracefully.\nAvailable in OS X v10.2 and later."
 errSSLClosedAbort,–9806,"The connection closed due to an error.\nAvailable in OS X v10.2 and later."
 errSSLXCertChainInvalid,–9807,"Invalid certificate chain.\nAvailable in OS X v10.2 and later."
 errSSLBadCert,–9808,"Bad certificate format.\nAvailable in OS X v10.2 and later."
 errSSLCrypto,–9809,"An underlying cryptographic error was encountered.\nAvailable in OS X v10.2 and later."
 errSSLInternal,–9810,"Internal error.\nAvailable in OS X v10.2 and later."
 errSSLModuleAttach,–9811,"Module attach failure.\nAvailable in OS X v10.2 and later."
 errSSLUnknownRootCert,–9812,"Certificate chain is valid, but root is not trusted.\nAvailable in OS X v10.2 and later."
 errSSLNoRootCert,–9813,"No root certificate for the certificate chain.\nAvailable in OS X v10.2 and later."
 errSSLCertExpired,–9814,"The certificate chain had an expired certificate.\nAvailable in OS X v10.2 and later."
 errSSLCertNotYetValid,–9815,"The certificate chain had a certificate that is not yet valid.\nAvailable in OS X v10.2 and later."
 errSSLClosedNoNotify,–9816,"The server closed the session with no notification.\nAvailable in OS X v10.2 and later."
 errSSLBufferOverflow,–9817,"An insufficient buffer was provided.\nAvailable in OS X v10.2 and later."
 errSSLBadCipherSuite,–9818,"A bad SSL cipher suite was encountered.\nAvailable in OS X v10.2 and later."
 errSSLPeerUnexpectedMsg,–9819,"An unexpected message was received.\nAvailable in OS X v10.3 and later."
 errSSLPeerBadRecordMac,–9820,"A record with a bad message authentication code (MAC) was encountered.\nAvailable in OS X v10.3 and later."
 errSSLPeerDecryptionFail,–9821,"Decryption failed.\nAvailable in OS X v10.3 and later."
 errSSLPeerRecordOverflow,–9822,"A record overflow occurred.\nAvailable in OS X v10.3 and later."
 errSSLPeerDecompressFail,–9823,"Decompression failed.\nAvailable in OS X v10.3 and later."
 errSSLPeerHandshakeFail,–9824,"The handshake failed.\nAvailable in OS X v10.3 and later."
 errSSLPeerBadCert,–9825,"A bad certificate was encountered.\nAvailable in OS X v10.3 and later."
 errSSLPeerUnsupportedCert,–9826,"An unsupported certificate format was encountered.\nAvailable in OS X v10.3 and later."
 errSSLPeerCertRevoked,–9827,"The certificate was revoked.\nAvailable in OS X v10.3 and later."
 errSSLPeerCertExpired,–9828,"The certificate expired.\nAvailable in OS X v10.3 and later."
 errSSLPeerCertUnknown,–9829,"The certificate is unknown.\nAvailable in OS X v10.3 and later."
 errSSLIllegalParam,–9830,"An illegal parameter was encountered.\nAvailable in OS X v10.3 and later."
 errSSLPeerUnknownCA,–9831,"An unknown certificate authority was encountered.\nAvailable in OS X v10.3 and later."
 errSSLPeerAccessDenied,–9832,"Access was denied.\nAvailable in OS X v10.3 and later."
 errSSLPeerDecodeError,–9833,"A decoding error occurred.\nAvailable in OS X v10.3 and later."
 errSSLPeerDecryptError,–9834,"A decryption error occurred.\nAvailable in OS X v10.3 and later."
 errSSLPeerExportRestriction,–9835,"An export restriction occurred.\nAvailable in OS X v10.3 and later."
 errSSLPeerProtocolVersion,–9836,"A bad protocol version was encountered.\nAvailable in OS X v10.3 and later."
 errSSLPeerInsufficientSecurity,–9837,"There is insufficient security for this operation.\nAvailable in OS X v10.3 and later."
 errSSLPeerInternalError,–9838,"An internal error occurred.\nAvailable in OS X v10.3 and later."
 errSSLPeerUserCancelled,–9839,"The user canceled the operation.\nAvailable in OS X v10.3 and later."
 errSSLPeerNoRenegotiation,–9840,"No renegotiation is allowed.\nAvailable in OS X v10.3 and later."
 errSSLServerAuthCompleted,-9841,"The server certificate is either valid or was ignored if verification is disabled.\nAvailable in OS X v10.6 through OS X v10.7."
 errSSLClientCertRequested,-9842,"The server has requested a client certificate.\nAvailable in OS X v10.6 and later."
 errSSLHostNameMismatch,-9843,"The host name you connected with does not match any of the host names allowed by the certificate. This is commonly caused by an incorrect value for the kCFStreamSSLPeerName property within the dictionary associated with the stream’s kCFStreamPropertySSLSettings key.\nAvailable in OS X v10.4 and later."
 errSSLConnectionRefused,–9844,"The peer dropped the connection before responding.\nAvailable in OS X v10.4 and later."
 errSSLDecryptionFail,–9845,"Decryption failed. Among other causes, this may be caused by invalid data coming from the remote host, a damaged crypto key, or insufficient permission to use a key that is stored in the keychain.\nAvailable in OS X v10.3 and later."
 errSSLBadRecordMac,–9846,"A record with a bad message authentication code (MAC) was encountered.\nAvailable in OS X v10.3 and later."
 errSSLRecordOverflow,–9847,"A record overflow occurred.\nAvailable in OS X v10.3 and later."
 errSSLBadConfiguration,–9848,"A configuration error occurred.\nAvailable in OS X v10.3 and later."
 </pre>
 
 
 */

@interface IMAPClient () {
    GCDAsyncSocket *_asyncSocket;
}
/// @name Private Properties
@property (nonatomic,readwrite) IMAPResponseParser              *parser;
@property (nonatomic, strong) dispatch_queue_t                  dispatchQueue;
@property (atomic, assign, readwrite) NSTimeInterval            idleSince;
@property (nonatomic, assign, readwrite) BOOL                   isFinished;
@property (nonatomic, assign, readwrite) BOOL                   isExecuting;
@property (nonatomic, assign, readwrite) BOOL                   isCommandComplete;
@property (nonatomic, assign, readwrite) UInt32                 commandIdentifier;
@property (nonatomic, strong) NSMutableArray                    *commandBlocks;

/// @name Private methods
-(void) iStreamHasBytesAvailable: (NSStream *)theStream;
-(void) streamEndEncountered: (NSStream *)theStream ;
-(void) oStreamHasSpaceAvailable: (NSStream *)theStream;
-(void) streamErrorOccurred: (NSStream *)theStream;
-(void) streamOpenCompleted: (NSStream *)theStream;
-(void) streamEventNone: (NSStream *)theStream;
-(void) close: (NSStream*) theStream;
-(void) closeStreams;


-(void) sendNextCommand;


//-(NSString *)



-(NSString*) commandTag;
-(NSString*) nextCommandTag;
-(NSString*) formatCommandToken: (NSString*) aCommandString;
-(BOOL) hasCapability: (NSString*) capability;


-(void) lightWeightSync;
-(void) syncQuanta;

@end

/*!
 At some point, the Ping.m code should be converted to NSStream and integrated into
 a Superclass of IMAPClient. This would enable testing of the network connection before
 attempting to connect. Is it possible to test if there is even a network adapter
 available before trying the network connection?
 */

@implementation IMAPClient

static NSUInteger  IMAPClientQueueCount = 0;

#pragma mark - init and cleanup

@synthesize isFinished = _finished;
@synthesize isCancelled = _cancelled;
@synthesize isExecuting;

@synthesize isBufferUpdated = _bufferUpdated;
@synthesize isSpaceAvailable = _spaceAvailable;


+ (NSString*) stateAsString: (IMAPClientStates) aState {
    NSString* stateString = nil;
    
    switch (aState) {
        case IMAPDisconnected:
            stateString = @"IMAPDisconnected";
            break;
        case IMAPNewConnection:
            stateString = @"IMAPNewConnection";
            break;
        case IMAPEstablished:
            stateString = @"IMAPEstablished";
            break;
        case IMAPGreeting:
            stateString = @"IMAPGreeting";
            break;
        case IMAPNotAuthenticated:
            stateString = @"IMAPNotAuthenticated";
            break;
        case IMAPAuthenticated:
            stateString = @"IMAPAuthenticated";
            break;
        case IMAPSelected:
            stateString = @"IMAPSelected";
            break;
        case IMAPLogout:
            stateString = @"IMAPLogout";
            break;
        case IMAPIdle:
            stateString = @"IMAPIdle";
            break;
            
        default:
            break;
    }
    return stateString;
}

- (NSString*) debugDescription {
    NSString* theDescription = [NSString stringWithFormat: @"Connection State: %@, isExecuting: %u, isFinished: %i, isCancelled %i",
                                [IMAPClient stateAsString: self.connectionState],
                                self.isExecuting,
                                self.isFinished,
                                self.isCancelled];
    return theDescription;
}

-(void) setConnectionState:(IMAPClientStates)connectionState {
    _connectionState = connectionState;
    DDLogVerbose(@"%@: ConnectionState: %@", NSStringFromClass([self class]), [IMAPClient stateAsString: _connectionState]);
}

- (id)initWithParentContext: (NSManagedObjectContext*) pcontext AccountID: (NSManagedObjectID *) anAccountID
{
    assert(anAccountID != nil);
    
    self = [super init];
    if (self) {
        // Initialization code here.
        _cancelled = NO;
        _finished = NO;
        isExecuting = NO;
        _connectionState = IMAPDisconnected;
        _connectionTimeOutSeconds = 120;
        _isConnectionTimedOut = NO;
        
        _dataBuffer = [[NSMutableArray alloc] initWithCapacity: 4];
        _bufferUpdated = NO;
        _isBufferComplete = YES;
        _spaceAvailable = NO;
        
        _eventHandlers = @{@(NSStreamEventHasBytesAvailable): @"iStreamHasBytesAvailable:" ,
                           @(NSStreamEventEndEncountered): @"streamEndEncountered:" ,
                           @(NSStreamEventHasSpaceAvailable): @"oStreamHasSpaceAvailable:" ,
                           @(NSStreamEventErrorOccurred): @"streamErrorOccurred:" ,
                           @(NSStreamEventOpenCompleted): @"streamOpenCompleted:" ,
                           @(NSStreamEventNone): @"streamEventNone:"};
        
        _commandIdentifier = 0;
        
        _serverCapabilities = [[NSMutableSet alloc] initWithCapacity: 5] ;
        
        _clientStore = [[IMAPCoreDataStore alloc] initWithParentContext: pcontext AccountID: anAccountID];
        
        _timeOutPeriod = -5; // outgoing timeout
        _runLoopInterval = 0.01; // seconds
        
        
        _syncQuantaLW = 1000;
        _syncQuantaF = 20;
        
        _mboxSequenceUIDMap = [[NSMutableDictionary alloc] initWithCapacity:10];
        _idleSince = [NSDate timeIntervalSinceReferenceDate];
    }
    
    return self;
}

-(id) init {
    return [self initWithParentContext: nil AccountID: nil];
}
-(void) dealloc {
    [self closeStreams];
    [_commandBlocks removeAllObjects];
}
-(NSMutableArray*) commandBlocks {
    if (!_commandBlocks) {
        _commandBlocks = [NSMutableArray arrayWithCapacity: 3];
    }
    return _commandBlocks;
}
-(IMAPResponseParser*) parser {
    if (!_parser) {
        _parser = [self newResponseParser];
    }
    return _parser;
}
-(IMAPResponseParser*) newResponseParser {
    IMAPResponseParser* newResponseParser = [IMAPResponseParser newResponseBufferWithStore: self.clientStore];
    newResponseParser.responseDelegate = self;
    newResponseParser.bufferDelegate = self;
    newResponseParser.timeOutPeriod = -2;
    return newResponseParser;
}
-(dispatch_queue_t) dispatchQueue {
    if (_dispatchQueue == nil) {
//        ++IMAPClientQueueCount;
//        NSString* queueLabel = [NSString stringWithFormat:@"com.moedae.imapaccount.%lu",(unsigned long)IMAPClientQueueCount];
//        dispatch_queue_t aQueue = dispatch_queue_create([queueLabel cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
//        _dispatchQueue = aQueue;
        _dispatchQueue = dispatch_get_main_queue();
    }
    return _dispatchQueue;
}

#pragma mark - High level App Methods
-(MBox*) selectedMBox {
    MBox* selectedBox = nil;
    
    if (self.clientStore) {
        selectedBox = self.clientStore.selectedMBox;
    }
    return selectedBox;
}
-(NSString*) selectedMBoxPath {
    NSString* path;
    MBox* selectedMBox = [self selectedMBox];
    if (selectedMBox) {
        path = [selectedMBox fullPath];
    }
    return path;
}
-(void) updateAccountFolderStructure {
    if ([self ensureOpenConnection]) {
        [self asyncUpdateAccountFolderStructure];
    }
}
-(void) asyncUpdateAccountFolderStructure {
    IMAPClient* __weak weakSelf = self;
    
    [self addCommandBlock: ^() {
        [weakSelf commandList: @""];
    }];
    
//    BOOL saveSuccess;
//    NSError *saveError = nil;
//    saveSuccess = [self.clientStore save: &saveError];
}
-(void) updateMissingFolders {
    if ([self ensureOpenConnection]) {
        NSArray* missingChildren = [self.clientStore.account fetchMissingChildren];
        for (MBox* box in missingChildren) {
            NSString* path = box.fullPath;
            IMAPClient* __weak weakSelf = self;
            
            [self addCommandBlock: ^() {
                [weakSelf commandList: path];
            }];
        }
    }
}
-(void) updateLatestMessagesForMBox:(MBox *)mbox olderThan:(NSTimeInterval)time {
    
    if ([self ensureOpenConnection]) {
 
        [self asyncSelectMBox: mbox];
        
        DDLogCVerbose(@"[%@ %@]Getting headers for \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.clientStore.selectedMBox.fullPath);
        
        [self asyncUpdateLatestMessagesForMBox: mbox olderThan: time];
    }
}
-(void) asyncSelectMBox: (MBox*) mbox {
    NSManagedObjectID* objectID = [mbox objectID];
    
    IMAPClient* __weak weakSelf = self;
    [self addCommandBlock: ^() {
        
        MBox* localMbox = (MBox*)[weakSelf.clientStore mboxForObjectID: objectID];
        
        NSString* mboxFullPath = localMbox.fullPath;
        
        // using full path string comparison to avoid potential issues with different contexts
        if (mboxFullPath && ![mboxFullPath isEqualToString: weakSelf.selectedMBoxPath]) {
            [weakSelf commandSelect: mboxFullPath];
        }
    }];
}
-(void) asyncUpdateLatestMessagesForMBox:(MBox *)mbox olderThan:(NSTimeInterval)time {
    IMAPClient* __weak weakSelf = self;

    [self addCommandBlock: ^() {
        NSInteger endRange = [weakSelf.clientStore.selectedMBox.serverMessages integerValue];
        if (endRange > 0) {
            NSInteger initialRange = endRange - 20;
            NSInteger startRange;
            startRange = (initialRange < 1) ? 1 : initialRange;
            
            [weakSelf commandFetchHeadersStart: startRange end: endRange];
        }
    }];
}
/*
 STATUS vs SELECT vs EXAMINE
 perhaps use EXAMINE rather than SELECT?
 Then query which boxes have changes and SELECT and get headers for them?
 
 Best to use SELECT. Status is for a separate net connection and Examine is read only.
 */
-(void) refreshAll {
        [self asyncRefreshAll];
        [self.delegate clientFinished: self]; // could this be sync not async?
}
-(void) asyncRefreshAll {
    //    self.isCancelled = NO;
    //    self.isFinished = NO;
    //    self.isExecuting = YES;
    //    self.isCommandComplete = YES;
    //
    //    NSError* error = nil;
    //    BOOL connected;
    //    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    //
    //    @try {
    //        @autoreleasepool {
    //            connected = [self openConnection: &error];
    //            if (connected && self.connectionState == IMAPAuthenticated) {
    //                // do some work process an event?
    //
    //                [self commandList];
    //
    //                for (MBox* box in self.clientStore.account.allNodes) {
    //                    if (self.connectionState != IMAPAuthenticated) {
    //                        self.isCancelled = YES;
    //                        break;
    //                    }
    //                    //[self commandSelect: @"INBOX"];
    //                    [self commandSelect: box.fullPath];
    //                    [self syncQuanta];
    //                    // Queue a command to set "isFinished"?
    //
    //                }
    //
    //            }
    //            else {
    //                // parse connection error
    //                DDLogVerbose(@"%@: ConnectionState %@, Streams connection error: %@.", NSStringFromSelector(_cmd), [IMAPClient stateAsString: self.connectionState], error);
    //
    //                while (!self.isCancelled) {
    //                    // do nothing
    //                    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow: self.runLoopInterval]];
    //                }
    //            }
    //
    //        }
    //    }
    //    @catch (NSException *exception) {
    //        self.isExecuting = NO;
    //
    //        NSString *exceptionMessage = [NSString stringWithFormat:@"%@\nReason: %@\nUser Info: %@", [exception name], [exception reason], [exception userInfo]];
    //        // Always log to console for history
    //        DDLogCVerbose(@"[%@ %@]Exception raised:\n%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd),exceptionMessage);
    //        DDLogCVerbose(@"[%@ %@]Backtrace: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [exception callStackSymbols]);
    //    }
    //    @finally {
    //        self.isExecuting = NO;
    //        [self closeStreams];
    //        self.isFinished = YES;
    //    }
}

-(void) loadFullMessage: (MBMessage*) message {
    MBox* mbox = message.mbox;
    
    if ([self ensureOpenConnection]) {

        [self asyncSelectMBox: mbox];
    
        [self asyncLoadFullMessage: message];
    }
}
/*!
 * Need to fetch the message based on the message objectID.
 * Get the message mail box.
 * IMAP SELECT the mail box
 * IMAP FETCH the full message
 * When IMAP response is finished, return.
 
 @param objectID NSManagedObjectID
 */
-(void) asyncLoadFullMessage: (MBMessage*) message {
    
     // fetch the selected message plus seek +- by one
    for (MBMime* part in message.allParts) {
        // doesn't handle partially loaded data
        // is network disconnect while loading
        // need to make sure data is always fully loaded before saving
        if (part.isLeaf && part.data == nil) {
            NSString* bodyIndex = part.bodyIndex;
            if ([bodyIndex length] > 0) {
                
                IMAPClient* __weak weakSelf = self;
                
                [self addCommandBlock: ^() {
                    [weakSelf commandFetchContentForMessage: message mimeParts: bodyIndex];
                }];
            }
        }
    }
}

-(void) testMessage:(NSString *)aMessage {
    DDLogVerbose(@"Testing Account name: %@", self.clientStore.account.name);
    DDLogVerbose(@"Just testing, passed: %@", aMessage);
}


#pragma mark - IMAP Sync methods
#pragma message "ToDo: How to deal with async connection error?"
-(BOOL) ensureOpenConnection {
    BOOL connectionOpen = NO;
    if (!self.isCancelled) {
        @try {
            if (self.connectionState == IMAPAuthenticated) {
                // connection is still open
                connectionOpen = YES;
            } else {
                NSError *error;
                connectionOpen = [self openConnection: &error];

                IMAPClient* __weak weakSelf = self;
                [self addCommandBlock: ^() {
                    [weakSelf commandCapability];
                }];
                [self addCommandBlock: ^() {
                    [weakSelf commandLogin];
                }];

                // TODO: test for error
                if (!connectionOpen) {
                    DDLogError(@"%@: ConnectionState %@, Streams connection error: %@.", NSStringFromSelector(_cmd), [IMAPClient stateAsString: self.connectionState], error);
                }
            }
        }
        @catch (NSException *exception) {
            NSString *exceptionMessage = [NSString stringWithFormat:@"%@\nReason: %@\nUser Info: %@", [exception name], [exception reason], [exception userInfo]];
            // Always log to console for history
            DDLogError(@"Exception raised:\n%@", exceptionMessage);
            DDLogError(@"Backtrace: %@", [exception callStackSymbols]);
        }
        @finally {
            //            [self closeStreams];
            //        self.isFinished = YES;
        }
    }
    return connectionOpen;
}
#pragma message "TODO: create regex for ip6"
/*!
 Opens a network IMAP connection using the account credentials and returns after the login has completed.
 Is NOT asynchronous. This command is blocking.
 
 @param anError error reference for returning a connection error.
 
 @return returns a BOOL connected status. YES for logged in. NO for everything else.
 */
-(BOOL) openConnection: (NSError**) anError {
    NSError* regexError = nil;
    SEL hostSelector;
    self.connectionState = IMAPNewConnection;
    
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
            //DDLogVerbose(@"%@: %@ resolved to address %@", NSStringFromSelector(_cmd), server, address);
            
            //            dispatch_queue_t selfQueue = dispatch_get_current_queue();
            //            _asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue: selfQueue];
            
            
            NSInputStream *tempIStream;
            NSOutputStream *tempOStream;
            
            [NSStream getStreamsToHost:host
                                  port: [self.clientStore.account.port intValue]
                           inputStream:&tempIStream
                          outputStream:&tempOStream];
            
            _iStream = tempIStream;
            _oStream = tempOStream;
            
            if ([self.clientStore.account.useTLS boolValue]) {
                [_iStream setProperty: NSStreamSocketSecurityLevelNone forKey: NSStreamSocketSecurityLevelKey];
                [_oStream setProperty: NSStreamSocketSecurityLevelNone forKey: NSStreamSocketSecurityLevelKey];
                
                NSDictionary *settings = @{(id)kCFStreamSSLAllowsExpiredCertificates: @YES,
                                           (id)kCFStreamSSLAllowsAnyRoot: @YES,
                                           (id)kCFStreamSSLValidatesCertificateChain: @NO,
                                           (id)(id)kCFStreamSSLPeerName: (id)kCFNull};
                
                CFReadStreamSetProperty((CFReadStreamRef)_iStream, kCFStreamPropertySSLSettings, (CFTypeRef)settings);
                CFWriteStreamSetProperty((CFWriteStreamRef)_oStream, kCFStreamPropertySSLSettings, (CFTypeRef)settings);
            }
 
            [_iStream setDelegate:self];
            [_oStream setDelegate:self];
            
            [_iStream scheduleInRunLoop: [NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
            [_oStream scheduleInRunLoop: [NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
            
            if ([_oStream streamStatus] == NSStreamStatusNotOpen) [_oStream open];
            if ([_iStream streamStatus] == NSStreamStatusNotOpen) [_iStream open];
            
            return YES;
        }
        else {
            DDLogVerbose(@"[%@ %@]; No address resolution for: %@.",
                         NSStringFromClass([self class]),
                         NSStringFromSelector(_cmd),
                         server);
            
            self.connectionState = IMAPDisconnected;
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
    [self close: _iStream];
    [self close: _oStream];
    self.connectionState = IMAPDisconnected;
    self.clientStore.selectedMBox = nil;
    [self.parser stopParsing];
    [self setParser: nil];
    
    DDLogVerbose(@"[%@ %@];", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}
#pragma message "ToDo: how to recover? how to inform? error handling if we can't save the context."
/// @name Sync methods
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
        
        NSNumber* lowestUID = [self.clientStore lowestUID];
        DDLogCVerbose(@"[%@ %@]lowestUID %hu", NSStringFromClass([self class]), NSStringFromSelector(_cmd),lowestUID);
        
        if (lowestUID == nil || [lowestUID unsignedLongLongValue] == 0) {
            // lowestUID was not found meaning cache is empty?
            // once there is a pre-fetch on load, there should never be 0
            maxFillUid = [self.clientStore.selectedMBox.serverUIDNext unsignedLongLongValue];
        } else {
            maxFillUid = [lowestUID unsignedLongLongValue];
        }
        DDLogCVerbose(@"[%@ %@]maxFillUid %hu", NSStringFromClass([self class]), NSStringFromSelector(_cmd),maxFillUid);
        if (maxFillUid > 1) {
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
                    [self commandUIDFetchHeadersStart: startRange end: endRange];
                    // Lock the persistent store
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
}
#pragma message "TODO needs major work, just for testing"
-(void) syncQuanta {
    BOOL saveSuccess;
    NSError *saveError = nil;
    
    //saveSuccess = [self.clientStore selectedMailBoxDeleteAllMessages: &saveError];
    saveSuccess = YES;
    
    
    
    if (saveSuccess) {
        
        
        UInt64 uidNext;
        
        UInt64 maxFillUid = [self.clientStore.selectedMBox.serverUIDNext unsignedLongLongValue];
        UInt64 startRange = maxFillUid - self.syncQuantaLW;
        if (startRange < 1) startRange = 1;
        
        if (maxFillUid >= 1) {
            DDLogCVerbose(@"[%@ %@]Getting headers for \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.clientStore.selectedMBox.fullPath);
            [self commandUIDFetchHeadersStart: startRange end: maxFillUid];
            // Lock the persistent store
            [self.clientStore save: &saveError];
            
        } else {
            DDLogCVerbose(@"[%@ %@]No headers for \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.clientStore.selectedMBox.fullPath);
        }
    }
}


#pragma mark - Stream Event Handling
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    NSString* eventHandler = (self.eventHandlers)[@(streamEvent)];
    if([self respondsToSelector:NSSelectorFromString(eventHandler)]){
        [self performSelector:NSSelectorFromString(eventHandler)
                   withObject: theStream];
    }else{
        DDLogError(@"[%@]: No stream event handler.", NSStringFromSelector(_cmd));
    }
}
#pragma clang diagnostic pop

-(void) streamEventNone: (NSStream *)theStream {
    DDLogVerbose(@"%[@]", NSStringFromSelector(_cmd));
    
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
    
    [self.parser startParsing];
    
    DDLogVerbose(@"%@: streamOpenCompleted. ConnectionState: %@", NSStringFromSelector(_cmd), [IMAPClient stateAsString: self.connectionState]);
}
-(void) iStreamHasBytesAvailable: (NSStream *)theStream {
    // iStream has input
    DDLogVerbose(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    [self getResponse];
}
#pragma message "ToDo: Check for certificate errors here?"
-(void) oStreamHasSpaceAvailable: (NSStream *)theStream {
    DDLogVerbose(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    [self sendNextCommand];
    // what if there is no command when this event is triggered but there is later?
    // need to set flag here
    // and call sendNextCommand when queueing the command if flag is set.
}
-(void) streamErrorOccurred: (NSStream *)theStream {
    NSError *theError = [theStream streamError];
    long errorCode = (long)[theError code];
    
    if ((errorCode <= -9819) && (errorCode >= -9840)) {
        // Errors in the range of –9819 through –9840 are fatal errors that are detected by the peer.
        self.connectionState = IMAPDisconnected;
        [self close: theStream];
        
        DDLogVerbose(@"[%@] %@",NSStringFromSelector(_cmd),
                     [NSString stringWithFormat:@"Error %li: %@", errorCode, [theError localizedDescription]]);
    } else {
        DDLogVerbose(@"[%@] %@, Continuing anyway.",NSStringFromSelector(_cmd),
                     [NSString stringWithFormat:@"Error %li: %@", errorCode, [theError localizedDescription]]);
    }
}
-(void) streamEndEncountered: (NSStream *)theStream {
    DDLogVerbose(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    self.connectionState = IMAPDisconnected;
    [self close: theStream];
    [self.parser stopParsing];
}

#pragma  mark - stream i/o
/*!
 self.parser is the client IMAPResponseParser.
 The parser is given a current command in [queueCommand:] which assumes previous command is complete.
 Command is queued from self.commandBlocks array [nextCommandBlock].
 [nextCommandBlock] called by [parseComplete:] when there is no current command.
 */
-(void) sendNextCommand {
    
    IMAPCommand* nextCommand = self.parser.command;
    if (!nextCommand.isActive) {
        NSString* commandString = (NSString*) [nextCommand nextOutput];
        if (commandString) {
            self.isSpaceAvailable = NO;
            nextCommand.isActive = YES;
            //
            //
            NSData * dataToSend = [commandString dataUsingEncoding: NSUTF8StringEncoding allowLossyConversion: YES];
            if (_oStream) {
                NSInteger remainingToWrite = [dataToSend length];
                void * marker = (void *)[dataToSend bytes];
                while (remainingToWrite > 0) {
                    NSInteger actuallyWritten = 0;
                    actuallyWritten = [(NSOutputStream*) _oStream write: marker maxLength: remainingToWrite];
                    if (actuallyWritten == -1) {
                        // there was an error
                        DDLogVerbose(@"[%@ %@] Error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [_oStream streamError]);
                        return; // need to handle error. Set a flag?
#pragma message "TODO: handle write error."
                    }
                    remainingToWrite -= actuallyWritten;
                    marker += actuallyWritten;
                }
            }
            self.idleSince = [NSDate timeIntervalSinceReferenceDate];
            DDLogInfo(@"[%@ %@: %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd), commandString);
        } else {
            self.isSpaceAvailable = YES;
        }
    } else {
        self.isSpaceAvailable = YES;
    }
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
        
        DDLogVerbose(@"[%@ %@]; %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd),  [[NSString alloc] initWithData: responseBuffer encoding: NSASCIIStringEncoding]);
    }
    self.idleSince = [NSDate timeIntervalSinceReferenceDate];
}



#pragma mark - methods to handle server responses

// called synchronously by loop extraction of response stack
//-(void) parseResponse {
//    NSString *currentString = [parser copyStringFromCurrentBuffer];
//    DDLogVerbose(@"%@: parsing: %@", NSStringFromSelector(_cmd), currentString);
//    [currentString release];
//
//    [parser parseResponse];
//    [parser evaluateResponse];
//}


-(void) commandDone: (IMAPParsedResponse*) parsedResponse {
    // response started with a tag
    NSError *saveError = nil;
    IMAPResponseStatus status = parsedResponse.status;
    BOOL success = NO;
    if (status==IMAPOK && parsedResponse.command.isDone) {
        // command completed successfully
    
        [self saveClientStore];
        MBCommandBlock successBlock = parsedResponse.command.successBlock;
        if (successBlock) {
            successBlock();
        }

    }
    DDLogVerbose(@"[%@:%@ %@]; Save Status %i: info %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), parsedResponse.command.tag, success, parsedResponse.command.info);
    
    parsedResponse.command = nil;
    self.parser.command = nil;
    if (self.commandBlocks.count > 0) {
        [self.commandBlocks removeObjectAtIndex: 0];
    }
}

-(void) commandContinue:(IMAPParsedResponse*) parsedResponse {
    DDLogVerbose(@"[%@ %@: %@]; %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), parsedResponse.command.tag, parsedResponse.tokens);
}

#pragma mark - command and response utility methods

/*!
 convenience method to reformat the command method tokens
 
 @param aCommandString NSString
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
 
 @param capability being checked for as an NSString
 */
-(BOOL) hasCapability:(NSString *)capability {
    return [self.serverCapabilities containsObject: capability];
}
-(void) saveClientStore {
    NSError* saveError;
    BOOL saveStatus;
    saveStatus = [self.clientStore save: &saveError];
    if (!saveStatus) {
        DDLogVerbose(@"[%@ %@]Save error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), saveError);
    }
}
#pragma mark - ResponseBuffer Delegate
-(void) parseComplete: (IMAPParsedResponse*) parsedResponse {
    NSArray* tokenArray = [parsedResponse.tokens tokenArray];
    DDLogCVerbose(@"[%@ %@]Response Tokens: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), tokenArray);
    
    
    [parsedResponse evaluate];
    
    // Save before evaluating next command/response
    [self saveClientStore];
    // if no command, remove from stack
    // if a command, is it done
    if (parsedResponse.command == nil) {
        [self nextCommandBlock];
    }
}
-(void) parseWaiting: (id) sender {
    // do nothing
}
-(void) parseUnexpectedEnd: (IMAPParsedResponse*) parsedResponse {
    if ([parsedResponse.command.atom isEqualToString: @"SELECT"]) {
        self.clientStore.selectedMBox = nil;
    }
}
-(void) parseError: (IMAPParsedResponse*) parsedResponse {
    if ([parsedResponse.command.atom isEqualToString: @"SELECT"]) {
        self.clientStore.selectedMBox = nil;
    }
}
-(void) parseTimeout: (IMAPParsedResponse*) parsedResponse {
    if ([parsedResponse.command.atom isEqualToString: @"SELECT"]) {
        self.clientStore.selectedMBox = nil;
    }
}

#pragma mark - Response Delegate

#pragma mark - Resp-text-codes
-(void) responseCapability: (NSArray *) tokens {
    for ( id argument in tokens) {
        [self.serverCapabilities addObject: [argument uppercaseString]];
    }
}
// or check for IMAPBYE in run loop?
-(void)responseBye: (IMAPParsedResponse*) response {
    DDLogVerbose(@"[%@ %@: %@]; %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), response.command.tag, response.tokens);
    [self closeStreams];
}
-(void) responseUnknown: (IMAPParsedResponse*) response {
    DDLogVerbose(@"[%@ %@: %@]; %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), response.command.tag, response.tokens);
}
-(void) responseIgnore: (IMAPParsedResponse*) response {
    DDLogVerbose(@"[%@ %@: %@]; %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), response.command.tag, response.tokens);
}


#pragma mark - MailBox-Data responses

// TODO: how to determine whether a pre-existing folder has been deleted on the server while
// offline? Same in reverse. A folder deleted on the client while offline needs to be deleted
// on the server side? Need a queue of offline commands executed to be replayed when online and
// before regular sync.
// TODO: offline re-sync later.


-(void) responseLsub: (IMAPParsedResponse*) response{
    
}

-(void) responseSearch: (IMAPParsedResponse*) response{
    
}



#pragma mark - command streaming methods
/// @name Command streaming methods

-(NSString*) commandTag {
    return [NSString stringWithFormat:@"moedae%05u", (unsigned int)self.commandIdentifier];
}

-(NSString*) nextCommandTag {
    self.commandIdentifier += 1;
    return [self commandTag];
}
-(void) queueCommand: (IMAPCommand*)command withSuccessBlock: (MBCommandBlock) block {
    self.parser.command = command;
    self.parser.command.tag = [self nextCommandTag];
    self.parser.command.successBlock = block;
    if (self.isSpaceAvailable) {
        [self sendNextCommand];
    }
}
-(void) addCommandBlock: (MBCommandBlock) aBlock {
    [self.commandBlocks addObject: aBlock];
    // if connection has been idle, the count would be zero and the block needs to be evaluated now.
    // on the other hand, do not evaluate right away if a command is underway.
    if (self.connectionState == IMAPAuthenticated && !self.parser.command) {
        aBlock();
    }
}
-(void) nextCommandBlock {
    if (self.commandBlocks.count > 0) {
        MBCommandBlock nextBlock = [self.commandBlocks firstObject];
        nextBlock();
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
    [self queueCommand: command withSuccessBlock: NULL];
}

-(void) commandNoop {
    IMAPCommand* command = [[IMAPCommand alloc] initWithAtom: @"NOOP"];
    [self queueCommand: command withSuccessBlock: NULL];
}

-(void) commandStartTLS{
    // unimplemented as unnecessary?
}
/*!
 Note: a server implementation MUST implement a
 configuration in which it does NOT permit any plaintext
 password mechanisms, unless either the STARTTLS command
 has been negotiated or some other mechanism that
 protects the session from password snooping has been
 provided.  Server sites SHOULD NOT use any configuration
 which permits a plaintext password mechanism without
 such a protection mechanism against password snooping.
 Client and server implementations SHOULD implement
 additional [SASL] mechanisms that do not use plaintext
 passwords, such the GSSAPI mechanism described in [SASL]
 and/or the [DIGEST-MD5] mechanism.
 
 Unless either the STARTTLS command has been negotiated or
 some other mechanism that protects the session from
 password snooping has been provided, a server
 implementation MUST implement a configuration in which it
 advertises the LOGINDISABLED capability and does NOT permit
 the LOGIN command.  Server sites SHOULD NOT use any
 configuration which permits the LOGIN command without such
 a protection mechanism against password snooping.  A client
 implementation MUST NOT send a LOGIN command if the
 LOGINDISABLED capability is advertised.
 */
#pragma message "TODO: Check for LOGINDISABLED and report"
-(void) commandLogin {
    // Check for auth capabilities
    IMAPCommand* command = nil;
    if ([self hasCapability: @"AUTH=PLAIN"] || [self hasCapability: @"AUTH=LOGIN"]) {
        command = [[IMAPCommand alloc] initWithAtom: @"login"];
        [command copyAddArgument: self.clientStore.account.username];
        [command copyAddArgument: self.clientStore.account.password];
        MBCommandBlock successBlock = ^() {
            self.connectionState = IMAPAuthenticated;
        };
        [self queueCommand: command withSuccessBlock: successBlock];
    }
}

/*!
 USE XLIST if available
 Just simple behaviour for now.
 Add arguments in the future?
 Add default to xlist if it exists in capabilities?
 */
-(void) commandList: (NSString *) mboxPath {
    // Just always list the full directory structure
    if ([self hasCapability: @"XLIST"]) {
        [self commandXList: mboxPath];
    } else {
        IMAPCommand* command = [[IMAPCommand alloc] initWithAtom: @"LIST"];
        [command copyAddArgument: [NSString stringWithFormat: @"\"%@\"",mboxPath]];
        [command copyAddArgument: @"%"];
        MBCommandBlock successBlock = ^() {
            [self updateMissingFolders];
        };
        [self queueCommand: command withSuccessBlock: successBlock];
    }
}

-(void) commandXList: (NSString *) mboxPath {
    // Just always list the full directory structure
    if ([self hasCapability: @"XLIST"]) {
        IMAPCommand* command = [[IMAPCommand alloc] initWithAtom: @"XLIST"];
        [command copyAddArgument: [NSString stringWithFormat: @"\"%@\"",mboxPath]];
        [command copyAddArgument: @"%"];
        MBCommandBlock successBlock = ^() {
            [self updateMissingFolders];
        };
        [self queueCommand: command withSuccessBlock: successBlock];
    } else {
        [self commandList: mboxPath];
    }
}

/*!
 No need for this with core data structure?
 */
-(void) commandListExtended: (NSString*) mboxPath {
    
}

#pragma message "TODO: how to let response know that the current command is for mbox arg?"

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
    [self queueCommand: command withSuccessBlock: NULL];
}

#pragma message "TODO: IDLE will not complete until \"done\" is sent. results in a continue state."
// need to handle continue state and send done before future commands.

/*!
 
 */
-(void) commandIdle {
    IMAPCommand* command = [[IMAPCommand alloc] initWithAtom: @"IDLE"];
    [self queueCommand: command withSuccessBlock: NULL];
    // change state?
    // commands need to check state and send done then wait for completion
    // before new command executes. Add to command class?
    //[self waitForCompletion];
    
}

/*!
 RFC 3501 pg 33
 "The SELECT command automatically deselects any
 currently selected mailbox before attempting the new selection.
 Consequently, if a mailbox is selected and a SELECT command that
 fails is attempted, no mailbox is selected."
 
 */
#pragma message "TODO: Check OK completion status before assigning selected mailbox."
-(void) commandSelect: (NSString *) mboxPath{
    //    MBox* previousSelectedMbox = self.clientStore.selectedMBox;
    
    // Start selection process for new selection
    // Selected box needs to be set before command is sent so the response
    // attributes can be assign to the appropriate box.
    // The response data does not specify the box.
    [self.clientStore selectMailBox: mboxPath];
    
    IMAPCommand* command = [[IMAPCommand alloc] initWithAtom: @"SELECT"];
    NSString* quotedPath = [NSString stringWithFormat:@"\"%@\"",mboxPath];
    command.mboxFullPath =  mboxPath;
    [command copyAddArgument: quotedPath];
    
    [self queueCommand: command withSuccessBlock: NULL];
}
-(void) commandFetchHeadersStart: (UInt64) startRange end: (UInt64) endRange {
    IMAPCommand* command = [[IMAPCommand alloc] initWithAtom: @"FETCH"];
    NSString *sequence = [NSString stringWithFormat: @"%llu:%llu", startRange, endRange];
    [command copyAddArgument: sequence];
    [command copyAddArgument: @"(FLAGS"];
    [command copyAddArgument: @"UID"];
    [command copyAddArgument: @"RFC822.SIZE"];
    [command copyAddArgument: @"RFC822.HEADER"];
    [command copyAddArgument: @"BODYSTRUCTURE)"];
    command.mboxFullPath = self.clientStore.selectedMBox.fullPath;
    [self queueCommand: command withSuccessBlock: NULL];
}

-(void) commandFetchContentStart: (UInt64) startRange end: (UInt64) endRange {
    IMAPCommand* command = [[IMAPCommand alloc] initWithAtom: @"FETCH"];
    NSString *sequence = [NSString stringWithFormat: @"%llu:%llu", startRange, endRange];
    [command copyAddArgument: sequence];
    [command copyAddArgument: @"(FLAGS"];
    [command copyAddArgument: @"UID"];
    [command copyAddArgument: @"RFC822.SIZE"];
    [command copyAddArgument: @"RFC822.HEADER)"];
    command.mboxFullPath = self.clientStore.selectedMBox.fullPath;
    [self queueCommand: command withSuccessBlock: NULL];
}
-(void) commandFetchContentForSequence:(UInt64)theSequence mimeParts:(NSString *)part {
    IMAPCommand* command = [[IMAPCommand alloc] initWithAtom: @"FETCH"];
    NSString *sequence = [NSString stringWithFormat: @"%llu", theSequence];
    [command copyAddArgument: sequence];
    [command copyAddArgument: [NSString stringWithFormat:@"(BODY[%@])", part]];
    command.mboxFullPath = self.clientStore.selectedMBox.fullPath;
    [self queueCommand: command withSuccessBlock: NULL];
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
-(void) commandUIDFetchHeadersStart: (UInt64) startRange end: (UInt64) endRange {
    IMAPCommand* command = [[IMAPCommand alloc] initWithAtom: @"UID FETCH"];
    NSString *sequence = [NSString stringWithFormat: @"%llu:%llu", startRange, endRange];
    [command copyAddArgument: sequence];
    [command copyAddArgument: @"(FLAGS"];
    //[command copyAddArgument: @"INTERNALDATE"];
    [command copyAddArgument: @"RFC822.SIZE"];
    [command copyAddArgument: @"RFC822.HEADER"];
    [command copyAddArgument: @"BODYSTRUCTURE)"];
    command.mboxFullPath = self.clientStore.selectedMBox.fullPath;
    [self queueCommand: command withSuccessBlock: NULL];
}

-(void) commandUIDFetchContentStart: (UInt64) startRange end: (UInt64) endRange {
    IMAPCommand* command = [[IMAPCommand alloc] initWithAtom: @"UID FETCH"];
    NSString *sequence = [NSString stringWithFormat: @"%llu:%llu", startRange, endRange];
    [command copyAddArgument: sequence];
    [command copyAddArgument: @"(FLAGS"];
    //[command copyAddArgument: @"INTERNALDATE"];
    [command copyAddArgument: @"RFC822.SIZE"];
    [command copyAddArgument: @"RFC822.HEADER)"];
    command.mboxFullPath = self.clientStore.selectedMBox.fullPath;
    [self queueCommand: command withSuccessBlock: NULL];
}
-(void) commandFetchContentForMessage:(MBMessage*)message mimeParts:(NSString *)part {
    UInt64 muid = [message.uid longLongValue];

    IMAPCommand* command = [[IMAPCommand alloc] initWithAtom: @"UID FETCH"];
    NSString *sequence = [NSString stringWithFormat: @"%llu", muid];
    [command copyAddArgument: sequence];
    [command copyAddArgument: [NSString stringWithFormat:@"(BODY[%@])", part]];
    command.mboxFullPath = self.clientStore.selectedMBox.fullPath;
    
#pragma message "ToDo: add connection and download error detection and only set cached if sucessful"
    
    MBCommandBlock successBlock = ^() {
        message.isFullyCached = @YES;
    };
    
    [self queueCommand: command withSuccessBlock: successBlock];
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

//-(void) commandFetch {
//    
//}


-(void) commandStore {
    
}

-(void) commandCopy {
    
}

-(void) commandUid {
    
}

@end