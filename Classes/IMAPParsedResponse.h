//
//  IMAPParsedResponse.h
//  MailBoxes
//
//  Created by Taun Chapman on 10/31/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMAPResponseDelegate.h"
#import "IMAPClientStore.h"
#import "MBTokenTree.h"

@class IMAPCommand;
@class IMAPCoreDataStore;


enum IMAPResponseType {
    IMAPResponseUnknown = 1,
    IMAPResponseIgnore,
    IMAPResponseContinue,
    IMAPResponseData,
    IMAPResponseDone
};
typedef UInt8 IMAPResponseType;

enum IMAPResponseStatus {
    IMAPNO = 1,
    IMAPOK,
    IMAPBAD,
    IMAPBYE
};
typedef UInt8 IMAPResponseStatus;

/*!
 A tokenized IMAP response.
 
 IMAPResponseBuffer fills the IMAPResponse with IMAP response tokens in the form of a MBTokenTree.
 
 The IMAPResponse can evaluate the tokens converting from tokenized string data to IMAP objects such as
 headers, MIME attachments, body, ...
 
 During conversion, the data is saved using a Core Data backend for persistence and indexing.
 
 
 */
@interface IMAPParsedResponse : NSObject

/// @name Properties
/*!
 The IMAPCommand which initiated the response.
 
 Enables determining the end of the response based on the IMAP command tag.
 */
@property (strong)              IMAPCommand                     *command;
/*!
 The parsed response as a MBTokenTree of strings
 */
@property (strong)              MBTokenTree                     *tokens;
@property (assign)              IMAPResponseType                type;
/*!
 The response status as returned by the server after the IMAPCommand.
 */
@property (assign)              IMAPResponseStatus              status;
@property (nonatomic,weak,readwrite) id <IMAPDataStore>         dataStore;
@property (nonatomic,strong)              NSMutableDictionary*  messageProperties;
@property (nonatomic,weak) id <IMAPParsedResponseDelegate>      delegate;

/// @name Property convenience methods
+ (NSString*) typeAsString: (IMAPResponseType) aType;
+ (NSString*) statusAsString: (IMAPResponseStatus) aStatus;


/*!
 Traverses the tokens tree.
 
 Determine response command tokens such as "CAPABILITY" converts the token to a method name by 
 prefixing "response" to the command token and converting the string to camel case. MBTokens acts 
 like a scanner so it knows the current token position. The "responseCommand" is called to evaluate
 the remaining tokens in the context of the specific command. If no method exists for the response command, 
 "responseUnknown" is called.
 
 To interpret a new IMAP response command, one would need to create a new IMAPResponse method of the form
 "responseNewCommandName".
 */
-(void) evaluate;
-(void) actOnResponseText;
-(void) actOnResponseState;
-(void) actOnResponseData;
-(void) actOnResponseDone;
-(void) actOnResponseContinue;

/// @name Delegate send off
-(void) responseCapability;
-(void) responseUnknown;
-(void) responseIgnore;
-(void) responseBye;

#pragma mark - client store send off
/// @name  MailBox-Data responses
/*!
 Evaluate tokens in response to a standard LIST command on the current selected mail box.
 
 #### Sample response
 
 * 12597 EXISTS
 * 0 RECENT
 * OK [UNSEEN 19] First unseen.
 * OK [UIDVALIDITY 1312094147] UIDs valid
 * OK [UIDNEXT 12598] Predicted next UID
 * OK [HIGHESTMODSEQ 1] Highest
 * OK [URLMECH INTERNAL] Mechanisms supported
 
 */
-(void) responseList;
-(void) responseXlist;
-(void) responseFlags;

-(void) responseReadOnly;
-(void) responseReadWrite;

-(void) responseStatus;
-(void) responseExists;
-(void) responseHighestmodseq;
-(void) responseRecent;
-(void) responseUidnext;
-(void) responseUidvalidity;
-(void) responseUnseen;

/// @name Response Message Data
-(void) responseExpunge;
-(void) responseFetch;
-(void) responseFetchedMessageFlags;
-(void) responseFetchedMessageEnvelope;
-(void) responseFetchedMessageInternaldate;
-(void) responseFetchedMessageRfc822;
-(void) responseFetchedMessageRfc822Size;
/*!
 Adds header name as key and and token as value to the self.messageProperties dictionary.
 
 Note: Only adds headers which are in the HeaderToModelMap static dictionary. 
 
 */
-(void) responseFetchedMessageRfc822Header;
-(void) responseFetchedMessageRfc822Text;
-(void) responseFetchedMessageBody;
-(void) responseFetchedMessageBodyText;
-(void) responseFetchedMessageBodystructure;

/// @name Need to implement
-(void) responseAlert;
-(void) responseBadcharset;
-(void) responseTrycreate;

@end
