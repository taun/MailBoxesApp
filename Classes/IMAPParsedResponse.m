//
//  IMAPParsedResponse.m
//  MailBoxes
//
//  Created by Taun Chapman on 10/31/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import "IMAPParsedResponse.h"
#import "IMAPCommand.h"
#import "IMAPCoreDataStore.h"
#import "RFC2822RawMessageHeader.h"

#import <MoedaeMailPlugins/NSString+IMAPConversions.h>
#import <MoedaeMailPlugins/NSDate+IMAPConversions.h>
#import <MoedaeMailPlugins/NSObject+TokenDispatch.h>

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

static const int ddLogLevel = LOG_LEVEL_INFO;

static     NSSet *RespDataStateTokens;
static     NSSet *RespDataCommandTokens;
static     NSSet *RespDataPostfixCommandTokens;
static     NSSet *RespDataTextCodeCommandTokens;
static     NSSet *RespDataFetchCommandTokens;
//static     NSSet *ClientStoreMessageTokens;
//static     NSSet *ClientStoreMailBoxTokens;
//static     NSSet *DelegateTokens;

/*!
 Static NSDictionary *HeaderToModelMap - Maps from IMAP header labels to MBox property names.
 */
static     NSDictionary *HeaderToModelMap;


@interface IMAPParsedResponse  ()

@property (nonatomic,readonly) dispatch_queue_t       delegateQueue;
-(void) performResponseMethodFromToken: (NSString *) commandToken;

-(void) localLog;

-(NSDate *) getAndConvertInternalDateFrom: (NSString *) stringWithRFC3501Date;
-(NSDate *) getAndConvert822DateFrom: (NSString *) stringWithRFC2822Date;


@end


@implementation IMAPParsedResponse


+ (NSString*) typeAsString: (IMAPResponseType) aType {
    NSString* typeString = nil;
    
    switch (aType) {
        case IMAPResponseUnknown:
            typeString = @"IMAPResponseUnknown";
            break;
        case IMAPResponseIgnore:
            typeString = @"IMAPResponseIgnore";
            break;
        case IMAPResponseContinue:
            typeString = @"IMAPResponseContinue";
            break;
        case IMAPResponseData:
            typeString = @"IMAPResponseData";
            break;
        case IMAPResponseDone:
            typeString = @"IMAPResponseDone";
            break;
            
        default:
            break;
    }
    return typeString;
}

+ (NSString*) statusAsString: (IMAPResponseStatus) aStatus {
    NSString* statusString = nil;
    
    switch (aStatus) {
        case IMAPNO:
            statusString = @"IMAPNO";
            break;
        case IMAPOK:
            statusString = @"IMAPOK";
            break;
        case IMAPBAD:
            statusString = @"IMAPBAD";
            break;
        case IMAPBYE:
            statusString = @"IMAPBYE";
            break;
        case 0:
            statusString = @"Not Set";
            break;
            
        default:
            break;
    }
    return statusString;
}

/*
 "Return-Path: newsinfo@9flavours.com
 Received: from mz0.moedae.com (LHLO mail.charcoalia.net) (68.238.253.173) by mail.charcoalia.net with LMTP; Sun, 31 Jul 2011 03:19:59 -0400 (EDT)
 Received: from localhost (localhost [127.0.0.1]) by mail.charcoalia.net (Postfix) with ESMTP id 67E9138784 for <taun@charcoalia.net>; Sun, 31 Jul 2011 03:19:59 -0400 (EDT)
 X-Virus-Scanned: amavisd-new at lpm.moedae.com
 X-Spam-Flag: NO
 X-Spam-Score: 3.936
 X-Spam-Level: ***
 X-Spam-Status: No, score=3.936 tagged_above=-10 required=5 tests=[BAYES_00=-1.9, FB_INDEPEND_RWD=2.799, HTML_MESSAGE=0.001, MIME_HEADER_CTYPE_ONLY=0.717, MIME_HTML_ONLY=0.723, SPF_HELO_PASS=-0.001, SPF_PASS=-0.001, T_RP_MATCHES_RCVD=-0.01, URIBL_WS_SURBL=1.608] autolearn=no
 Received: from mail.charcoalia.net ([127.0.0.1]) by localhost (mail.charcoalia.net [127.0.0.1]) (amavisd-new, port 10024) with ESMTP id 4wq-n-eLkZEn for <taun@charcoalia.net>; Sun, 31 Jul 2011 03:19:54 -0400 (EDT)
 Received: from 9flavours.com (listserv.9flavours.com [71.6.200.53]) by mail.charcoalia.net (Postfix) with SMTP id 4D14638781 for <taun@charcoalia.net>; Sun, 31 Jul 2011 03:19:53 -0400 (EDT)
 Content-Type: text/html; charset=\"US-ASCII\"
 Date: Sun, 31 Jul 2011 00:20:04 -0700
 To: taun@charcoalia.net
 From: 9Flavours.com <newsinfo@9flavours.com>
 X-Mailer: Version 5.0
 Subject: A Home Depot gift card - our gift to you
 Organization: 9Flavours.com
 Message-Id: <20110731071954.4D14638781@mail.charcoalia.net>
*/
+(void) initialize {
    if (RespDataStateTokens == nil) {
        RespDataStateTokens = [[NSSet alloc] initWithObjects: @"OK",@"NO",@"BAD", nil];
    }
    if (RespDataCommandTokens == nil) {
        RespDataCommandTokens = [[NSSet alloc] initWithObjects: @"BYE",@"CAPABILITY",@"FETCH",
                                 @"FLAGS",@"LIST",@"XLIST",@"LSUB",@"SEARCH",@"STATUS", nil];
    }
    if (RespDataPostfixCommandTokens == nil) {
        RespDataPostfixCommandTokens = [[NSSet alloc] initWithObjects: @"EXPUNGE",@"FETCH",@"EXISTS",@"RECENT", nil];
    }
    if (RespDataTextCodeCommandTokens == nil) {
        RespDataTextCodeCommandTokens = [[NSSet alloc] initWithObjects: @"ALERT",@"BADCHARSET",
                                         @"CAPABILITY",@"PARSE",@"PERMANENTFLAGS",@"READ-ONLY",
                                         @"READ-WRITE",@"TRYCREATE",@"UIDNEXT",@"UIDVALIDITY",
                                         @"UNSEEN", nil];
    }
    if (RespDataFetchCommandTokens == nil) {
        RespDataFetchCommandTokens = [[NSSet alloc] initWithObjects: @"FLAGS",@"ENVELOPE",
                                      @"INTERNALDATE",@"RFC822",@"RFC822.HEADER",@"RFC822.TEXT",
                                      @"RFC822.SIZE",@"BODY", @"BODY[TEXT]", @"BODYSTRUCTURE",
                                      @"UID", nil];
    }
    if (HeaderToModelMap == nil) {
        HeaderToModelMap = @{@"": @"",
                             @"SUBJECT": @"Subject",
                             @"DATE": @"DateSent",
                             @"FROM": @"AddressFrom",
                             @"SENDER": @"AddressSender",
                             @"REPLY-TO": @"AddressReplyTo",
                             @"RECEIVED": @"DateReceived",
                             @"TO": @"AddressesTo",
                             @"CC": @"AddressesCc",
                             @"BCC": @"AddressesBcc",
                             @"MESSAGE-ID": @"MessageId",
                             @"ORGANIZATION": @"Organization",
                             @"RETURN-PATH": @"ReturnPath",
                             @"X-SPAM-FLAG": @"XSpamFlag",
                             @"X-SPAM-LEVEL": @"XSpamLevel",
                             @"X-SPAM-SCORE": @"XSpamScore",
                             @"X-SPAM-STATUS": @"XSpamStatus" };
    }
}

- (id)init {
    self = [super init];
    if (self) {
        _tokens = [[MBTokenTree alloc] init];
        _command = nil;
        _dataStore = nil;
        _messageProperties = [[NSMutableDictionary alloc] initWithCapacity: 10];
        
        _type = 0;
        _status = 0;
    }
    return self;
}
-(dispatch_queue_t) delegateQueue {
    return dispatch_get_main_queue();
}

-(void) dealloc {
    self.delegate = nil;
}

#pragma mark - debug help
- (NSString*) debugDescription {
    NSString* theDescription = [NSString stringWithFormat: @"Type: %@, Status: %@, %@, %@",
                                [IMAPParsedResponse typeAsString: self.type],
                                [IMAPParsedResponse statusAsString: self.status],
                                [self.command debugDescription],
                                [[self.tokens tokenArray] description]];
    return theDescription;
}

#pragma mark - parsing
/*!
 @method startParse
 @discussion is it 'state', 'capability', 'mailbox', 'message', 'bye'
 status =
 OK |
 NO |
 BAD
 
 capability =
 capability
 
 mailbox =
 FLAGS " SP flag-list /
 LIST " SP mailbox-list / "LSUB" SP mailbox-list /
 "SEARCH" *(SP nz-number) / "STATUS" SP mailbox SP "(" [status-att-list] ")" /
 number SP "EXISTS" / number SP "RECENT"
 12345 EXISTS
 12345 RECENT
 
 message = ^nz-number SP ("EXPUNGE" / ("FETCH" SP msg-att))
 12345 EXPUNGE
 12345 FETCH
 
 bye =
 BYE
 
 @result void
 */
/*!
 Need to look for
 "* command results"
 "* command results {xxx}
 "* OK [results] description
 "* #### command .... where #### = UID
 "tag OK | BAD | BYE result
 "* BYE"
 
 perform parsing as follows
 if "continue" (^+ ) performSelector responseContinue:
 if "tagged" performSelector responseTagged:
 if "data" (^* ) performSelector    responseData:
 
 What to do about "moedae002 OK logged in"?
 */
-(void) evaluate {
    // data, done or continue?
    // literal?
    // tagged?
    
    NSString *token = nil;
    if ((token = [self.tokens scanString])) {
        if ([token compare: @"*"] == NSOrderedSame){
            self.type = IMAPResponseData;
            [self actOnResponseData];
            
        } else if ([token compare: @"+"] == NSOrderedSame){
            self.type = IMAPResponseContinue;
            [self actOnResponseContinue];
            
        } else {
            // should be a tagged response
            // put the tag back.
            NSString *ctag = token;
            [self.tokens insertObject: ctag];
            [self actOnResponseDone];
        }
    }
    [self.tokens removeAllObjects];
}

#pragma mark - traversing response branches/states


/*!
 Response started with "*"
 Followed by one of:
 state = OK | NO | BAD resp-text
 
 capability-data = CAPABILITY SP capabilities...
 
 message-data = nz-number SP ("EXPUNGE" / ("FETCH" SP msg-att))
 
 mailbox-data = "FLAGS" SP flag-list
 / "LIST" SP mailbox-list
 / "LSUB" SP mailbox-list
 / "SEARCH" *(SP nz-number)
 / "STATUS" SP mailbox SP "(" [status-att-list] ")"
 / number SP "EXISTS"
 / number SP "RECENT"
 
 bye =  BYE SP resp-text
 
 resp-text = ["[" resp-text-code "]" SP] text
 
 @abstract Response started with "*"
 
 @result void
 */
-(void) actOnResponseData {
    // 1. starts with a number
    // 2. starts with a command token
    NSAssert([self.tokens count] > 0, @"%@ - No tokens!", NSStringFromSelector(_cmd));
    NSString *firstToken = [[self.tokens scanString] uppercaseString];
    
    if ([RespDataStateTokens containsObject: firstToken]) {
        
        [self actOnResponseState];
        
    } else if ([RespDataCommandTokens containsObject: firstToken]) {
        // send command directly to delegate
        
        [self performResponseMethodFromToken: firstToken];
        
    } else {
        // either number postfix commands or unknown
        NSAssert([self.tokens count] > 0, @"%@ - No tokens!", NSStringFromSelector(_cmd));
        NSString *secondToken = [self.tokens scanString];
        if ([RespDataPostfixCommandTokens containsObject: secondToken]){
            // these are the commands which are number then command such as "12312 EXISTS"
            // extract number and store in argument then send to command
            NSNumber* dataArg = @([firstToken integerValue]);
            
            if (dataArg != 0) {
                // valid number, put back in number string token
                [self.tokens insertObject: firstToken];
                [self performResponseMethodFromToken: secondToken];
            } else {
                // wasn't number and we have a problem
                [self.delegate responseUnknown: self];
            }
        } else {
            // we have an unknown response
            [self.delegate responseUnknown: self];
        }
    }
    
}

#pragma message "TODO: parse continue"
-(void) actOnResponseContinue {
    // do nothing yet
    [self.delegate commandContinue: self];
}

-(void) actOnResponseDone {
    // need to handle this better
    // handle the command tag compare
    // then state and propogate to command
    // then arguments
    // then command info with remaining tokens
    // then dispatch ?
    // Do all of above in "actOnResponseDone"
    // actOnResponseDone calls actOnResponseData!
    NSString *ctag = [self.tokens scanString];
    if ([self.command.tag caseInsensitiveCompare: ctag] == NSOrderedSame) {
        // response tag matches command tag
        self.type = IMAPResponseDone;
        [self actOnResponseState];
        self.command.info = [[self.tokens tokenArray] componentsJoinedByString: @" "];
        self.command.isDone = YES;
    } else {
        // Shouldn't hapen so what to do?
        DDLogWarn(@"%@ Command tag %@ did not match response tag %@", NSStringFromSelector(_cmd), self.command.tag, ctag);
    }
    
    [self.delegate commandDone: self];
}

#pragma message "TODO: add test for self.status == IMAPNO"
#pragma message "TODO: add test for self.status == IMAPBAD"
// then log and possibly present to user or console.
-(void) actOnResponseState {
    // response is ok no bad
    // need to set state,
    NSAssert([self.tokens count] > 0, @"%@ - No tokens!", NSStringFromSelector(_cmd));
    NSString *token = [self.tokens scanString];
    
    if ([token caseInsensitiveCompare: @"OK"] == NSOrderedSame) {
        self.status = IMAPOK;
        [self actOnResponseText];
    } else if ([token caseInsensitiveCompare: @"NO"] == NSOrderedSame) {
        self.status = IMAPNO;
    } else if ([token caseInsensitiveCompare: @"BAD"] == NSOrderedSame) {
        self.status = IMAPBAD;
    }
    self.command.responseStatus = self.status;
}

-(void) actOnResponseText {
    // RESPONSE-TEXT-CODE
    // Parsing adds contents of "[command values ... ]" as a subArray
    // detect subarray then first token of subarray is command
    //
    
    NSAssert([self.tokens count] > 0, @"%@ - No tokens!", NSStringFromSelector(_cmd));
    MBTokenTree* nextTokens = nil;
    if ((nextTokens = [self.tokens scanSubTree]) ) {
        [self.tokens removeAllObjects];
        self.tokens = nextTokens;
        NSString *token = [[self.tokens scanString] uppercaseString];
        if ([RespDataTextCodeCommandTokens containsObject: token]) {
            [self performResponseMethodFromToken: token];
        } else {
            // unknown token
        }
    }
    
}


#pragma mark - Delegate send off
-(void) responseCapability {
    [self.delegate responseCapability: self.tokens.tokenArray];
}

-(void) responseBye {
    [self localLog];
    self.status = IMAPBYE;
    [self.delegate responseBye: self];
}
-(void) responseUnknown {
    self.type = IMAPResponseIgnore;
    self.status = 0;
    [self.delegate responseUnknown: self];
}

-(void) responseIgnore {
    self.type = IMAPResponseUnknown;
    self.status = 0;
    [self.delegate responseIgnore: self];
}


#pragma mark - Client Store send off
#pragma mark - MailBox-Data responses
/*!
 \Noinferiors
 It is not possible for any child levels of hierarchy to exist
 under this name; no child levels exist now and none can be
 created in the future.
 
 \Noselect
 It is not possible to use this name as a selectable mailbox.
 
 \Marked
 The mailbox has been marked "interesting" by the server; the
 mailbox probably contains messages that have been added since
 the last time the mailbox was selected.
 
 mailbox-data       = "LIST" SP mailbox-list
 mailbox-list       = "(" [mbx-list-flags] ")" SP (DQUOTE QUOTED-CHAR DQUOTE / nil) SP mailbox
 mbx-list-flags     = *(mbx-list-oflag SP) mbx-list-sflag *(SP mbx-list-oflag) / mbx-list-oflag *(SP mbx-list-oflag)
 mbx-list-oflags    = "\Noinferiors" / flag-extension ; Other flags; multiple possible per LIST response
 mbx-list-sflags    = "\Noselect" / "\Marked" / "\Unmarked" ; Selectability flags; only one per LIST response
 mailbox            = "INBOX" / astring
 
 */
-(void) responseList{
    [self responseXlist];
}

/*!
 Evaluate tokens in response to a standard XLIST command on the current selected mail box.
 
 1st ".." content is path separator which can be nil
 2nd ".." is mailbox path
 tokenize path by separator
 create if necessary each mailbox in path
 Special use identifiers = ALL ARCHIVE DRAFTS FLAGGED JUNK SENT TRASH
 Isolate "(...)" and separate by SP
 Ignore all in "( )" except \Noinferiors & special use
 
 "***Need to flag folders with special use
 "***Need to flag folders with \Noinferiors
 "***Need to not add folders with \Noselect
 
 "***Need a generic core data method to create object if necessary and return object
 can be used for folders and flags and ?
 implement as core data object class method or category
 
 #### Sample command forms
 
 * LIST (\HasNoChildren) "." "INBOX.F_Happening"
 * XLIST (\HasNoChildren \Drafts) "/" "Drafts"
 * XLIST (\HasNoChildren) "/" "admin@moedae.com's Inbox/mz1.moedaworks.com"
 
 */
-(void) responseXlist{
    [self localLog];
    
    NSAssert([self.tokens count] >= 3, @"%@ - No tokens!", NSStringFromSelector(_cmd));
    NSMutableArray *flagTokens = [[self.tokens scanSubTree] tokenArray]; // TODO: check object class to make sure it is an array
    
    NSString *separator = [self.tokens scanString];
    
    NSString *path = [self.tokens scanString];
    
    
    [self.dataStore setMailBoxFlags: flagTokens onPath: path withSeparator: separator];
}
/*!
 Contents:   flag parenthesized list
 The FLAGS response occurs as a result of a SELECT or EXAMINE
 command.  The flag parenthesized list identifies the flags (at a
 minimum, the system-defined flags) that are applicable for this
 mailbox.  Flags other than the system flags can also exist,
 depending on server implementation.
 The update from the FLAGS response MUST be recorded by the client.
 */
-(void) responseFlags {
    [self localLog];
    
    NSAssert([self.tokens count] > 0, @"%@ - No tokens!", NSStringFromSelector(_cmd));
    NSMutableArray *flagTokens = [[self.tokens scanSubTree] tokenArray]; // TODO: check for array at 0
    [self.dataStore setMailBox: self.command.mboxFullPath AvailableFlags: flagTokens];
}

/*!
 PERMANENTFLAGS
 Crispin
 Followed by a parenthesized list of flags, indicates which of
 the known flags the client can change permanently.  Any flags
 that are in the FLAGS untagged response, but not the
 PERMANENTFLAGS list, can not be set permanently.  If the client
 attempts to STORE a flag that is not in the PERMANENTFLAGS
 list, the server will either ignore the change or store the
 state change for the remainder of the current session only.
 The PERMANENTFLAGS list can also include the special flag \*,
 which indicates that it is possible to create new keywords by
 attempting to store those flags in the mailbox.
 */
-(void) responsePermanentflags {
    [self localLog];
    
    NSAssert([self.tokens count] > 0, @"%@ - No tokens!", NSStringFromSelector(_cmd));
    NSMutableArray *flagTokens = [[self.tokens scanSubTree] tokenArray]; // TODO: check for array at 0
    [self.dataStore setMailBox: self.command.mboxFullPath PermanentFlags: flagTokens];
}

-(void) responseReadOnly {
    [self localLog];
    // set MBox mode to RO
    [self.dataStore setMailBoxReadOnly: self.command.mboxFullPath];
}

-(void) responseReadWrite {
    [self localLog];
    // set MBox mode to RO
    [self.dataStore setMailBoxReadWrite: self.command.mboxFullPath];
}

/*!
 MESSAGES
 The number of messages in the mailbox.
 RECENT
 The number of messages with the \Recent flag set.
 UIDNEXT
 The next unique identifier value of the mailbox.  Refer to
 section 2.3.1.1 for more information.
 UIDVALIDITY
 The unique identifier validity value of the mailbox.  Refer to
 section 2.3.1.1 for more information.
 UNSEEN
 The number of messages which do not have the \Seen flag set.
 */
-(void) responseStatus {
    
}

-(void) responseExists {
    [self localLog];
    
    NSNumber *arg = [self.tokens scanNumber];
    if (arg != nil) {
        [self.dataStore setMailBox: self.command.mboxFullPath serverMessageCount: arg];
    }
}

-(void) responseRecent {
    [self localLog];
    
    NSAssert([self.tokens count] > 0, @"%@ - No tokens!", NSStringFromSelector(_cmd));
    NSNumber *arg = [self.tokens scanNumber];
    if (arg != nil) {
        [self.dataStore setMailBox: self.command.mboxFullPath serverRecentCount: arg];
    }
}

-(void) responseHighestmodseq {
    [self localLog];
    NSAssert([self.tokens count] > 0, @"%@ - No tokens!", NSStringFromSelector(_cmd));
    NSNumber *arg = [self.tokens scanNumber];
    if (arg != nil) {
        [self.dataStore setMailBox: self.command.mboxFullPath serverHighestmodseq: arg];
    }
}

-(void) responseUidnext {
    [self localLog];
    NSAssert([self.tokens count] > 0, @"%@ - No tokens!", NSStringFromSelector(_cmd));
    NSNumber *arg = [self.tokens scanNumber];
    if (arg != nil) {
        [self.dataStore setMailBox: self.command.mboxFullPath Uidnext: arg];
    }
}

-(void) responseUidvalidity {
    [self localLog];
    NSAssert([self.tokens count] > 0, @"%@ - No tokens!", NSStringFromSelector(_cmd));
    NSNumber *arg = [self.tokens scanNumber];
    if (arg != nil) {
        [self.dataStore setMailBox: self.command.mboxFullPath Uidvalidity: arg];
    }
}

-(void) responseUnseen {
    [self localLog];
    NSAssert([self.tokens count] > 0, @"%@ - No tokens!", NSStringFromSelector(_cmd));
    NSNumber *arg = [self.tokens scanNumber];
    if (arg != nil) {
        [self.dataStore setMailBox: self.command.mboxFullPath serverUnseen: arg];
    }
}

#pragma mark - Response Message Data

-(void) responseExpunge {
    
}

/*!
 CommandFetch must always include UID to enable proper response parsing!
 
 NOTE: arg is a sequence number NOT a UID number.
 the UID is in the response "UID 1231" use regex to extract UID and number.
 
 
 discard arg which is a sequence
 
 extract all text within "("
 extract first word as method selector passing remaining string
 method extract arguments and returns.
 extract next word as method selector ...
 repeat until string is empty
 
 parseMessageDataName -
 parseMessageDataUid, parseMessageDataEnvelope, parseMessageDataFlags
 
 Need UID and Envelope information before message can be created.
 Passing a MBMessage instance based on UID
 
 sample command> uid fetch 100:110 (FLAGS INTERNALDATE RFC822.SIZE ENVELOPE
 
 
 * 120 FETCH (UID 120 FLAGS (\Seen) INTERNALDATE "29-Jan-2008 11:47:36 -0500" RFC822.SIZE 24143
 ENVELOPE ("Mon, 4 Feb 2008 06:17:46 -0000" "You've been granted access"
 (("Borders Rewards Perks" NIL "Borders" "e.bordersstores.com"))
 (("Borders Rewards Perks" NIL "Borders" "e.bordersstores.com"))
 (("Borders Rewards Perks" NIL "support-b09pdbwaxsb41ra3r0ag2bq8we1dqm" "e.bordersstores.com"))
 ((NIL NIL "taun" "charcoalia.net"))
 NIL NIL NIL "<b09pdbwaxsb41ra3r0ag2bq8we1dqm.822905916.2082@mta45.e.bordersstores.com>")
 )
 
 message-data =     nz-number SP ("EXPUNGE" / ("FETCH" SP msg-att))
 
 msg-att =          "(" (msg-att-dynamic / msg-att-static) *(SP (msg-att-dynamic / msg-att-static)) ")"
 
 msg-att-dynamic =  "FLAGS" SP "(" [flag-fetch *(SP flag-fetch)] ")"  ; MAY change for a message
 
 msg-att-static =    "ENVELOPE" SP envelope / "INTERNALDATE" SP date-time /
 "RFC822" [".HEADER" / ".TEXT"] SP nstring /
 "RFC822.SIZE" SP number /
 "BODY" ["STRUCTURE"] SP body /
 "BODY" section ["<" number ">"] SP nstring /
 "UID" SP uniqueid
 ; MUST NOT change for a message
 
 */
-(void) responseFetch {
    // Must always use UID version of fetch command
    // "*" and "FETCH" had already been removed
    NSAssert([self.tokens count] > 0, @"%@ - No tokens!", NSStringFromSelector(_cmd));
    
    NSNumber* sequence = [self.tokens scanNumber];
    
    if (sequence != nil) {
        // valid integer conversion
        
        MBTokenTree *fetchArgs = [self.tokens scanSubTree];
        [self.tokens removeAllObjects];
        self.tokens = fetchArgs;
        
        // UID is required
        // search array for UID then extract UID and value for all other calls
        
        NSNumber *messageUid = nil;
        NSUInteger integerUid = 0;
        id tmp;
        
        NSDictionary* uidKeyValue = [self.tokens scanForKeyValue: @"UID"];
        if ((tmp=uidKeyValue[@"UID"]) != nil) {
            if ([tmp isKindOfClass: [NSString class]]) {
                integerUid = [((NSString *)tmp) longLongValue];
                if (integerUid != 0) {
                    messageUid = @(integerUid);
                }
            }
        }
        
        if (messageUid != 0) {
            
            // reset messageProperties
            [self.messageProperties removeAllObjects];
            
            (self.messageProperties)[@"Sequence"] = @([sequence integerValue]);
            
            NSString *token;
            while (![self.tokens isEmpty]) {
                token = [[self.tokens scanString] uppercaseString];
                if ([RespDataFetchCommandTokens containsObject: token]) {
                    // using hyphen in @"%@-%@" will keep the CamelCase for token and Fetched-Message
                    // hyphen is removed before calling method name
                    NSString* prePreFixedToken = [NSString stringWithFormat: @"%@-%@",@"Fetched-Message", token];
                    [self performResponseMethodFromToken: prePreFixedToken ];
                }
            }
            if (self.command.isNewMessage) {
                [self.dataStore newMessage: messageUid propertiesFromDictionary: self.messageProperties];
            } else {
                [self.dataStore setMessage: messageUid propertiesFromDictionary: self.messageProperties];
            }
            [self.messageProperties removeAllObjects];
        } else {
#pragma message "ToDo: error finding UID?"
        }
        
        
        //            NSInteger uidInteger = [[fetchArgs objectAtIndex: 1] integerValue];
        //            if (uidInteger != 0) {
        //                NSNumber *messageUid = [NSNumber numberWithInteger: uidInteger];
        //
        //                [self.clientStore setMessage: messageUid sequence: [NSNumber numberWithInteger: sequence]];
        //
        //
        //
        //                [self.clientStore setMessage:messageUid flags: [fetchArgs objectAtIndex:3]];
        //
        //                [self parseMessageUid: messageUid DataInternalDate: [fetchArgs objectAtIndex: 5]];
        //
        //                [self parseMessageUid: messageUid DataRFC822Size: [fetchArgs objectAtIndex: 7]];
        //
        //                [self parseMessageUid: messageUid DataEnvelope:[fetchArgs objectAtIndex: 9]];
        //            }
        
    } else {
#pragma message "ToDo: what to do if bad sequence number"
    }
}

-(void) responseFetchedMessageFlags {
    NSAssert([self.tokens count] > 0, @"%@ - No tokens!", NSStringFromSelector(_cmd));
    (self.messageProperties)[@"Flags"] = [self.tokens scanToken];
}
-(void) responseFetchedMessageEnvelope {
    // nothing yet, just dispose
    NSAssert([self.tokens count] > 0, @"%@ - No tokens!", NSStringFromSelector(_cmd));
    [self.tokens removeToken];
}
/*!
 INTERNALDATE "26-Jul-2011 07:48:41 -0400"
 token is of form "26-Jul-2011 07:48:41 -0400"
 
 rfc3501:  DQUOTE date-day-fixed "-" date-month "-" date-year SP time SP zone DQUOTE
 */
-(void) responseFetchedMessageInternaldate  {
    NSAssert([self.tokens count] > 0, @"%@ - No tokens!", NSStringFromSelector(_cmd));
    
    NSDate* dateSent = [self.tokens scanDateFromRFC3501Format];
    if (dateSent) {
        (self.messageProperties)[@"DateSent"] = dateSent;
    }
}

#pragma message "ToDo: parse complete RFC822 raw message"
-(void) responseFetchedMessageRfc822 {
    
}
-(void) responseFetchedMessageRfc822Size {
    NSAssert([self.tokens count] > 0, @"%@ - No tokens!", NSStringFromSelector(_cmd));
    
    NSNumber* rfcSize = [self.tokens scanNumber];
    if (rfcSize != nil) {
        (self.messageProperties)[@"Rfc2822size"] = rfcSize;
    }
}
#pragma message "ToDo: Add responseFetchedMessageBodyHeader version"
#pragma message "ToDo: Change message summary to a real summary rather than raw header"
#pragma message "ToDo: Perhaps get first 2 lines of text portion of body when fetching headers?"
-(void) responseFetchedMessageRfc822Header {
    NSAssert([self.tokens count] > 0, @"%@ - No tokens!", NSStringFromSelector(_cmd));
    RFC2822RawMessageHeader *header = [[RFC2822RawMessageHeader alloc] initWithString: [self.tokens scanString]];
    
    // Rewrite to just pass a dictionary to the clientStore and let it process everything at once.
    // Maybe can even dispatch it async.
    
    (self.messageProperties)[@"Summary"] = header.unfolded;
    
    for (NSString* headerKey in header.fields) {
        NSString* modelKey = HeaderToModelMap[headerKey];
        if (modelKey) {
            (self.messageProperties)[modelKey] = (header.fields)[headerKey];
        }
    }
}
-(void) responseFetchedMessageRfc822Text {
    
}

#pragma message "ToDo: look for key [header] in tokens and parse so body.peek[header] can replace rfc822.header"
/*!
 a007 uid fetch 1100 (body[2])
 * 1100 FETCH (UID 1100 BODY[2] {510708}
 followed by 510708 octets of data
 responseBuffer will have already replaced {510708} with actual data
 
 
 Token Structure
 raw response (BODY[2.1] {} asdasda ...)
 tokenized (BODY (PART) data)
 dictionary key: "body" object (part, data)
 */
-(void) responseFetchedMessageBody {
    DDLogVerbose(@"Body response tokens (%@)", [self.tokens tokenArray]);
    MBTokenTree* bodyPartTree = [self.tokens scanSubTree];
    if (bodyPartTree) {
        NSString* bodyPart = [bodyPartTree scanString];
        NSString* data = [self.tokens scanToken];
        if ([bodyPart isEqualToString: @"HEADER"]) {
            // response to body[header]
            RFC2822RawMessageHeader *header = [[RFC2822RawMessageHeader alloc] initWithString: data];

            for (NSString* headerKey in header.fields) {
                NSString* modelKey = HeaderToModelMap[headerKey];
                if (modelKey) {
                    (self.messageProperties)[modelKey] = (header.fields)[headerKey];
                }
            }
        } else {
            NSArray* bodyArray = @[bodyPart, data];
            (self.messageProperties)[[@"body" mdcStringAsSelectorSafeCamelCase]] = bodyArray;
        }
    }
 
    bodyPartTree = nil;
}

-(void) responseFetchedMessageBodyText {
    
}

-(void) responseFetchedMessageBodystructure {
    NSAssert([self.tokens count] > 0, @"%@ - No tokens!", NSStringFromSelector(_cmd));
    DDLogVerbose(@"BodyStructure:\n%@", self.tokens.tokenArray);
    // starts as a parenthesized list and parser should have converted
    // to a nested array of tokens
    MBTokenTree* bodystructure = [self.tokens scanSubTree];
    if (bodystructure) {
        [self.messageProperties setObject: [bodystructure tokenArray] forKey: [@"bodystructure" mdcStringAsSelectorSafeCamelCase]];
    }
    bodystructure = nil;
}


#pragma mark - utility

-(void) performResponseMethodFromToken: (NSString *) commandToken {
    [self performCleanedSelectorString: commandToken prefixedBy: @"response" fallbackSelector: @"responseUnknown"];
}

-(void) localLog {
    if (YES) {
        DDLogVerbose(@"%@:%@ Tokens %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [self.tokens tokenArray]);
    }
}


@end
