//
//  IMAPResponse.h
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


@interface IMAPResponse : NSObject {
    id          _delegate;
}
@property (strong)  IMAPCommand                     *command;
@property (strong)  MBTokenTree                     *tokens;
@property (assign)  IMAPResponseType                type;
@property (assign)  IMAPResponseStatus              status;
@property (nonatomic, weak, readwrite) id <IMAPClientStore> clientStore;
@property (strong)  NSMutableDictionary*            messageProperties;

#pragma mark - property convenience methods
+ (NSString*) typeAsString: (IMAPResponseType) aType;
+ (NSString*) statusAsString: (IMAPResponseStatus) aStatus;

#pragma mark - initial flow
-(id <IMAPResponseDelegate>)delegate;
-(void)setDelegate:(id)newDelegate;

-(void) evaluate;
-(void) actOnResponseText;
-(void) actOnResponseState;
-(void) actOnResponseData;
-(void) actOnResponseDone;
-(void) actOnResponseContinue;

#pragma mark - delegate send off
-(void) responseCapability;
-(void) responseUnknown;
-(void) responseIgnore;
-(void) responseBye;

#pragma mark - client store send off
#pragma mark - MailBox-Data responses
/*!
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

#pragma mark - Response Message Data
-(void) responseExpunge;
-(void) responseFetch;
-(void) responseFetchedMessageFlags;
-(void) responseFetchedMessageEnvelope;
-(void) responseFetchedMessageInternaldate;
-(void) responseFetchedMessageRfc822;
-(void) responseFetchedMessageRfc822Size;
-(void) responseFetchedMessageRfc822Header;
-(void) responseFetchedMessageRfc822Text;
-(void) responseFetchedMessageBody;
-(void) responseFetchedMessageBodyText;
-(void) responseFetchedMessageBodystructure;

#pragma mark - implement
-(void) responseAlert;
-(void) responseBadcharset;
-(void) responseTrycreate;

@end
