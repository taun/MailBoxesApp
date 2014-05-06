//
//  IMAPClient.h
//  MailBoxes
//
//  Created by Taun Chapman on 8/8/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IMAPResponseDelegate.h"
#import "IMAPResponseParser.h"
#import "IMAPParsedResponse.h"
#import "IMAPCommand.h"

#import "MBAccountsCoordinator.h"

@class GCDAsyncSocket;

@class IMAPCommand;
@class MBox;
@class MBMessage;
@class IMAPCoreDataStore;
@class IMAPMemCacheStore;
@class IMAPResponseParser;

/*!
 @header
 
 more later
 
 */


enum IMAPClientStates {
    IMAPDisconnected = 0,
    IMAPNewConnection,
    IMAPEstablished,
    IMAPGreeting,
    IMAPNotAuthenticated,
    IMAPAuthenticated,
    IMAPSelected,
    IMAPIdle,
    IMAPLogout
};


typedef UInt8 IMAPClientStates;



/*!
 IMAPClient is the primary connector to an IMAP server.

 ## IMAPClient Process flow
 
 1. IMAPClient is associated with 1 account in initWithParentContext:accountID:
 2. High level IMAPClient command is requested such as loadFullMessageID:
 2. The high level method opens the network connection and executes the necessary low level IMAP commands.
 3. IMAPClient queues a command for the account IMAP server.
 4. IMAPClient inserts the server response data into an IMAPResponseBuffer for parsing and tokenizing.
 5. When the response complete is received for the current command, the IMAPResponseBuffer is considered complete and the raw ascii is parsed returning an IMAPResponse with a MBTokenTree.
 6. The IMAPClient asks the IMAPResponse to evaluate the tokens in the MBTokenTree.
 7. IMAPResponse evaluation looks for the first command in the tokens then calls the corresponding named method.
 7. The IMAPResponse responseCommand method extracts the appropriate token values and passes them to the <IMAPClientStore> implementation. The values are passed to the ClientStore as the original raw strings.
 It is up to the ClientStore to either store the data as raw ascii or transform the values to some other form. The current IMAPClientStore implmentation (IMAPCoreDataStore) transforms the values to objects and stores the objects
 using Core Data.
 7. When the high level command is complete, the network connection is closed.
 7. If the network connection times out, the connection is closed.
 7. If the IMAPClient property isCancelled is set True, the network connection is closed.
 7. The IMAPClient status is monitored via the NSOperation properties isFinished, isExecuting and isCancelled.

 ## IMAP Server API Notes from RFC 3501
 
 ### State Diagram
 
<pre>

        ---------- connection established --------
 
                            ||
                            \/

        ------------- server greeting ------------

                || (1)          || (2)       || (3)
                \/              ||           ||
         +-----------------+    ||           ||
         |Not Authenticated|    ||           ||
         +-----------------+    ||           ||
          || (7)   || (4)       ||           ||
          ||       \/           \/           ||
          ||     +----------------+          ||
          ||     | Authenticated  |<=++      ||
          ||     +----------------+  ||      ||
          ||       || (7)   || (5)   || (6)  ||
          ||       ||       \/       ||      ||
          ||       ||    +--------+  ||      ||
          ||       ||    |Selected|==++      ||
          ||       ||    +--------+          ||
          ||       ||       || (7)           ||
          \/       \/       \/               \/

        ----------------- Logout -----------------

                            ||
                            \/

        ----- both sides close the connection ----
 
</pre>
 
 ### State Transitions
 
 1. connection without pre-authentication (OK greeting)
 2. pre-authenticated connection (PREAUTH greeting)
 3. rejected connection (BYE greeting)
 4. successful LOGIN or AUTHENTICATE command
 5. successful SELECT or EXAMINE command
 6. CLOSE command, or failed SELECT or EXAMINE command
 7. LOGOUT command, server shutdown, or connection closed
 
 IMAPrev4 specifies state only changes if command is successful,
 losing network connection or server does bye.
 
 @see IMAPResponseParser, IMAPParsedResponse
 */
@interface IMAPClient : NSObject <NSStreamDelegate, IMAPParsedResponseDelegate, IMAPResponseParserDelegate> {
    
@private
    BOOL            _finished;
    BOOL            _cancelled;
    BOOL            _bufferUpdated;
    BOOL            _spaceAvailable;
    
    NSInputStream*  _iStream;
    NSOutputStream* _oStream;
    NSDictionary*   _eventHandlers;
    
    NSMutableArray*  _dataBuffer;
}

#pragma message "ToDo add isAuthenticated, isConnected, both set to NO by a \"BYE\" response"
///@name Properties
@property (nonatomic, strong) id<IMAPClientDelegate>           delegate;
@property (nonatomic,readonly) MBox                           *selectedMBox;
@property (nonatomic,readonly) NSString                       *selectedMBoxPath;
@property (nonatomic,readonly) NSTimeInterval                  idleSince;
/*!
 Core Data Protocol account information.
 */
@property (nonatomic,readonly) IMAPResponseParser            *parser;
@property (nonatomic, strong) IMAPCoreDataStore              *coreDataStore;
@property (nonatomic, strong) IMAPMemCacheStore              *memCacheStore;

/*!
 Here as part of the NSOperation api to indicate the threaded job is finished.
 Used by the routine which submitted the job.
 */
@property (nonatomic, assign, readonly) BOOL                isFinished;
@property (nonatomic, assign, readonly) BOOL                isExecuting;
/*!
 another NSOperation api property.
 */
@property (atomic, assign, readwrite) BOOL                  isCancelled;
/*!
 flag to indicate the local buffer has been updated by a stream asynchronous read event.
 Needs to be cleared when???
 */
@property (atomic, assign, readwrite) BOOL                  isBufferUpdated;
@property (atomic, assign, readwrite) BOOL                  isBufferComplete;
@property (atomic, assign) NSUInteger                       dataBufferRemainingBytes;

/*!
 flag to indicate the outputStream spaceAvailable event has triggered.
 Needs to be cleared when submitting more to the outputStream.
 */
@property (atomic, assign, readwrite) BOOL                  isSpaceAvailable;
/*!
 local instance var to store inputStream responses.
 */
@property (atomic, strong) NSMutableArray*                  dataBuffer;

/*!
 Dictionary of event handler selectors as a string.
 Used instead of a switch:case: for handling asychronous stream events.
 */
@property (nonatomic,strong, readonly) NSDictionary*        eventHandlers;

/*!
 rfc3501 Each client command is
 prefixed with an identifier (typically a short alphanumeric string,
 e.g., A0001, A0002, etc.) called a "tag".  A different tag is
 generated by the client for each command. 
 */
@property (nonatomic, assign, readonly) UInt32              commandIdentifier;
/*!
 current connection state as per rfc 3501
 */
@property (nonatomic, assign) IMAPClientStates              connectionState;
@property (nonatomic, assign) NSUInteger                    connectionTimeOutSeconds;
@property (nonatomic, assign) BOOL                          isConnectionTimedOut;

/*!
 lets us know the server has finished responding to a command 
 and the next command can be queued.
 */
@property (nonatomic, assign, readonly) BOOL                isCommandComplete;
    
/// @name IMAP Server properties
/*!
 for caching the server capabilities
 */
@property (nonatomic, strong, readwrite) NSMutableSet*      serverCapabilities;

@property (assign) NSTimeInterval                           timeOutPeriod; //seconds
@property (assign) NSTimeInterval                           runLoopInterval; //seconds

@property (assign)  NSUInteger                              syncQuantaLW;
@property (assign)  NSUInteger                              syncQuantaF;

/*!
 Dictionary for each account mbox using full path as key
 value is array of UIDs where array index is sequence number
 */
@property (strong) NSMutableDictionary                      *mboxSequenceUIDMap;

@property (weak)   NSManagedObjectContext                   *parentContext;

+ (NSString*) stateAsString: (IMAPClientStates) aState;

- (NSString*) debugDescription;
/// @name Init
/*!
 Designated initializer
 
 @param pcontext Parent NSManagedObjectContext
 @param anAccount a CoreData user account object
 @return intialised IMAPClient object or nil
 */
-(id) initWithParentContext: (NSManagedObjectContext*) pcontext AccountID: (NSManagedObjectID *) anAccount;
/*!
 Blocking call. Only returns if the connection is open and authenticated or opening
 the connection failed.
 
 @return YES if connection is open and authenticated, NO is open failed.
 */
-(BOOL) ensureOpenConnection;
/*!
 Blocking. Opens a new network connection using the account information.
 Send IMAP Login and capability commands. Saves result of capability to 
 the appropriate MBAccount properties.
 
 @param anError an NSError reference for returning the potential error.
 
 @return whether the connection and login was successful.
 */
-(BOOL) openConnection: (NSError**) anError;


-(void) getResponse;

#pragma mark - High Level App Methods
#pragma message "TODO: convert High level methods to a protocol"
/// @name High Level App Methods
//-(void) refreshAll;
-(void) updateAccountFolderStructure;
-(void) updateLatestMessagesForMBox: (MBox*) mbox;
-(void) updateLatestMessagesForMBox: (MBox*) mbox
                          olderThan: (NSTimeInterval)time;
-(void) loadFullMessage: (MBMessage*) message;
-(void) testMessage: (NSString*) aMessage;



#pragma mark - IMAP Commands
/// @name IMAP Commands

#pragma mark - any state
/// @name Any state
/*!
 Arguments:  none

 Responses:  REQUIRED untagged response: CAPABILITY
 
 Result:     OK - capability completed
             BAD - command unknown or arguments invalid
 */
-(void) commandCapabilityWithSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;


/*!
 Arguments:  none

 Responses:  no specific responses for this command (but see below)
 
 Result:     OK - noop completed
             BAD - command unknown or arguments invalid
 */
-(void) commandNoopWithSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;


/*!
 @method commandLogout

 @discussion 
 Arguments:  none
 Responses:  REQUIRED untagged response: BYE
 Result:     OK - logout completed
 BAD - command unknown or arguments invalid */
-(void) commandLogoutWithSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;


/*!
 @method commandStartTLS

 @discussion seems unneccessary in these days. Requires starting in non SSL mode at a different
 port then switching to the SSL port. Most if not all systems support starting in SSL which means
 starttls never needs to be issued?
 
 Arguments:  none
 Responses:  no specific response for this command
 Result:     OK - starttls completed, begin TLS negotiation
 BAD - command unknown or arguments invalid
 */
-(void) commandStartTLSWithSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;


/*!
 @method commandAuthenticate

 @discussion 
 Arguments:  authentication mechanism name
 Responses:  continuation data can be requested
 Result:     OK - authenticate completed, now in authenticated state
 NO - authenticate failure: unsupported authentication
 mechanism, credentials rejected
 BAD - command unknown or arguments invalid,
 authentication exchange cancelled
 */
-(void) commandAuthenticateWithSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;


/*!
 @method commandLogin

 @discussion 
 Arguments:  user name
 password
 Responses:  no specific responses for this command
 Result:     OK - login completed, now in authenticated state
 NO - login failure: user name or password rejected
 BAD - command unknown or arguments invalid */
-(void) commandLoginWithSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;


#pragma mark - authenticated state
/// @name Authenticated state
/*!
 Arguments:  mailbox name
 
 Responses:  REQUIRED untagged responses: FLAGS, EXISTS, RECENT
             REQUIRED OK untagged responses:  UNSEEN,  PERMANENTFLAGS, UIDNEXT, UIDVALIDITY

 Result:     OK - select completed, now in selected state
             NO - select failure, now in authenticated state: no such mailbox, can’t access mailbox
             BAD - command unknown or arguments invalid
 
 @param mboxPath full mail box IMAP path as a NSString
 
 */
-(void) commandSelect: (NSString *) mboxPath withSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;


/*!
 Responses:  REQUIRED untagged responses: FLAGS, EXISTS, RECENT
             REQUIRED OK untagged responses:  UNSEEN,  PERMANENTFLAGS, UIDNEXT, UIDVALIDITY
 
 Result:     OK - examine completed, now in selected state
             NO - examine failure, now in authenticated state: no such mailbox, can’t access mailbox
             BAD - command unknown or arguments invalid 
 
 @param mbox the Core Data MBox object to examine.
 */
-(void) commandExamine: (MBox *)mbox withSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;


/*!
 Responses:  no specific responses for this command
 
 Result:     OK - create completed
             NO - create failure: can’t create mailbox with that name
             BAD - command unknown or arguments invalid 
 
 @param mbox the Core Data MBox object to create.
 */
-(void) commandCreate: (MBox *)mbox withSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;



/*!
 Responses:  no specific responses for this command
 
 Result:     OK - delete completed
             NO - delete failure: can’t delete mailbox with that name
             BAD - command unknown or arguments invalid
 
 @param mbox the Core Data MBox object to delete.
*/
-(void) commandDelete: (MBox *)mbox withSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;


/*!
 Responses:  no specific responses for this command

 Result:     OK - rename completed
             NO - rename failure: can’t rename mailbox with that name, can’t rename to mailbox with that name
             BAD - command unknown or arguments invalid
 
 @param mbox the Core Data MBox object to rename.
 @param newName new mailbox name
*/
-(void) commandRename: (MBox *)mbox to: (NSString *) newName withSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;


/*!
 Responses:  no specific responses for this command
 
 Result:     OK - subscribe completed
             NO - subscribe failure: can’t subscribe to that name
             BAD - command unknown or arguments invalid
 
 @param mbox the Core Data MBox object to subscribe.
 */
-(void) commandSubscribe: (MBox *)mbox withSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;

/*!
 Responses:  no specific responses for this command

 Result:     OK - unsubscribe completed
             NO - unsubscribe failure: can’t unsubscribe that name
             BAD - command unknown or arguments invalid

 @param mbox the Core Data MBox object to unsubscribe.
 */
-(void) commandUnSubscribe: (MBox *)mbox withSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;

/*!
 @method commandList
 
 @discussion 
 Arguments:  reference name
 mailbox name with possible wildcards
 Responses:  untagged responses: LIST
 Result:     OK - list completed
 NO - list failure: can’t list that reference or name
 BAD - command unknown or arguments invalid
 Example:
    C: A101 LIST "" ""
     "* LIST (\HasNoChildren) "/" "INBOX"
     "* LIST (\HasNoChildren) "/" "Notes"
     "* LIST (\HasNoChildren) "/" "ToDo"
     "* LIST (\Noselect \HasChildren) "/" "[Gmail]"
     "* LIST (\HasChildren \HasNoChildren) "/" "[Gmail]/All Mail"

 The character "*" is a wildcard, and matches zero or more
 characters at this position.  The character "%" is similar to "*",
 but it does not match a hierarchy delimiter.  If the "%" wildcard
 is the last character of a mailbox name argument, matching levels
 of hierarchy are also returned.
 
 */
-(void) commandList: (NSString*) mboxPath withSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;
// TODO: GMail needs custom LIST/XLIST to handle labels and "[GMAIL]/..."
// GMAIL does not have folders all 'folders' are labels.
// TODO: utilize \Marked for syncs
/*!
 @method commandXList
 
 @discussion 
 Arguments:  reference name
 mailbox name with possible wildcards
 Responses:  untagged responses: LIST
 Result:     OK - list completed
 NO - list failure: can’t list that reference or name
 BAD - command unknown or arguments invalid
 Example:
 a004 XLIST "" "*"
 "* XLIST (\HasChildren \Inbox) "/" "Inbox"
 "* XLIST (\Noselect \HasChildren) "/" "[Gmail]"
 "* XLIST (\HasNoChildren \AllMail) "/" "[Gmail]/All Mail"
 "* XLIST (\HasNoChildren \Drafts) "/" "[Gmail]/Drafts"
 "* XLIST (\HasNoChildren \Sent) "/" "[Gmail]/Sent Mail"
 "* XLIST (\HasNoChildren \Spam) "/" "[Gmail]/Spam"
 "* XLIST (\HasNoChildren \Starred) "/" "[Gmail]/Starred"
 "* XLIST (\HasNoChildren \Trash) "/" "[Gmail]/Trash"
 "* XLIST (\HasNoChildren) "/" "test"
 
 XLIST is identical to LIST except that it also provides a 
 localized name and attributes for special folders. These attributes 
 let the client know which folders are special (eg. \AllMail). 
 The current list of special folders is: Inbox, Starred, Sent Items, 
 Draft, Spam, All Mail. 
 */
-(void) commandXList: (NSString*) mboxPath withSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;

/*!
 @method commandListExtended
 
 @discussion This extension is identified by the capability string
 "LIST-EXTENDED"
 
 
*/
-(void) commandListExtended: (NSString*) mboxPath withSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;

/*!
 Arguments:  reference name
                mailbox name with possible wildcards
 Responses:  untagged responses: LSUB
 Result:     OK - lsub completed
 NO - lsub failure: can’t list that reference or name
 BAD - command unknown or arguments invalid */
-(void) commandLsubWithSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;

/*!
 Responses:  untagged responses: STATUS

 Result:     OK - status completed
             NO - status failure: no status for that name
             BAD - command unknown or arguments invalid
 
 @param mbox the Core Data MBox object.
 */
-(void) commandStatus: (MBox *)mbox withSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;

/*!
 OPTIONAL flag parenthesized list
 
 OPTIONAL date/time string, message literal
 
 Responses:  no specific responses for this command
 
 Result:     OK - append completed
             NO - append error: can’t append to that mailbox, error in flags or date/time or message text
             BAD - command unknown or arguments invalid
 
 @param mbox the Core Data MBox object to append.
 */
-(void) commandAppend: (MBox *)mbox withSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;

#pragma mark - selected state
/// @name Selected State
// CHECK, CLOSE, EXPUNGE, SEARCH, FETCH, STORE, COPY, and UID

/*!
 CHECK Command
 
 Arguments:  none
 
 Responses:  no specific responses for this command
 
 Result:     OK - check completed
             BAD - command unknown or arguments invalid
 */
-(void) commandCheckWithSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;

/*!
 CLOSE Command

 Arguments:  none
 
 Responses:  no specific responses for this command
 
 Result:     OK - close completed, now in authenticated state
             BAD - command unknown or arguments invalid
 */
-(void) commandCloseWithSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;

/*!
 EXPUNGE Command
 
 Arguments:  none
 
 Responses:  untagged responses: EXPUNGE
 
 Result:     OK - expunge completed
             NO - expunge failure: can’t expunge (e.g., permission denied)
             BAD - command unknown or arguments invalid
 */
-(void) commandExpungeWithSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;

/*!
 SEARCH Command
 Arguments:  OPTIONAL [CHARSET] specification
 searching criteria (one or more)
 Responses:  REQUIRED untagged response: SEARCH
 Result:     OK - search completed
 NO - search error: can’t search that [CHARSET] or
 criteria
 BAD - command unknown or arguments invalid
 */
-(void) commandSearchWithSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;

/*!
 FETCH Command
 
 Arguments:  sequence set, message data item names or macro
 
 Responses:  untagged responses: FETCH
 
 Result:     OK - fetch completed
             NO - fetch error: can’t fetch that data
             BAD - command unknown or arguments invalid

 CommandFetch must always include UID to enable proper response parsing!

 @param startRange an IMAP UID
 @param endRange an IMAP UID
 */
//-(void) commandFetch;
-(void) commandFetchSequenceUIDMap: (UInt64) startRange end: (UInt64) endRange withSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;
-(void) commandFetchHeadersStart: (UInt64) startRange end: (UInt64) endRange withSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;
-(void) commandFetchContentStart: (UInt64) startRange end: (UInt64) endRange withSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;
-(void) commandFetchContentForSequence:(UInt64)theSequence mimeParts:(NSString *)part withSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;
-(void) commandUIDFetchHeadersUIDSetString: (NSString*) uidString withSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;
-(void) commandUIDFetchHeadersStart: (UInt64) startRange end: (UInt64) endRange withSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;
-(void) commandUIDFetchContentStart: (UInt64) startRange end: (UInt64) endRange withSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;
-(void) commandFetchContentForMessage: (MBMessage*) message mimeParts: (NSString*) part withSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;

/*!
 STORE Command
 
 Arguments:  sequence set, message data item name, value for message data item
 
 Responses:  untagged responses: FETCH
 
 Result:     OK - store completed
             NO - store error: can’t store that data
             BAD - command unknown or arguments invalid
 
 */
-(void) commandStoreWithSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;

/*!
 COPY Command
 
 Arguments:  sequence set, mailbox name
 
 Responses:  no specific responses for this command
 
 Result:     OK - copy completed
             NO - copy error: can’t copy those messages or to that name
             BAD - command unknown or arguments invalid
 
 */
-(void) commandCopyWithSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;

/*!
 UID Command
 
 Arguments:  command name, command arguments
 
 Responses:  untagged responses: FETCH, SEARCH
 
 Result:     OK - UID command completed
             NO - UID command error
             BAD - command unknown or arguments invalid
 
 */
-(void) commandUidWithSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;

-(void) commandIdleWithSuccessBlock: (MBCommandBlock) successBlock withFailBlock: (MBCommandBlock) failBlock;



@end
