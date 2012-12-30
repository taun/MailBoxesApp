//
//  IMAPResponseDelegate.h
//  MailBoxes
//
//  Created by Taun Chapman on 9/29/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
@class IMAPResponse;

@protocol IMAPResponseDelegate <NSObject>


// MailboxRepsonses
//-(void) responseLsub: (id) response;
//-(void) responseSearch: (id) response;
//-(void) responseStatus: (id) response;
//-(void) responseExists: (id) response;
//-(void) responseRecent: (id) response;

// Message responses
//-(void) responseExpunge: (id) response;
//-(void) responseFetch: (id) response;

// Resp-text-codes
//-(void) responseAlert: (id) response;
//-(void) responseBadcharset: (id) response;
//-(void) responseParse: (id) response;
//-(void) responsePermanentflags: (id) response;
//-(void) responseReadOnly: (id) response;
//-(void) responseReadWrite: (id) response;
//-(void) responseTrycreate: (id) response;
//-(void) responseUidnext: (id) response;
//-(void) responseUidvalidity: (id) response;
//-(void) responseUnseen: (id) response;

-(void) commandDone: (IMAPResponse*) response;
-(void) commandContinue: (IMAPResponse*) response;

#pragma mark - new delegate methods
-(void) responseUnknown: (IMAPResponse*) response;
-(void) responseIgnore: (IMAPResponse*) response;
-(void) responseBye: (IMAPResponse*) response;
// Resp-text-codes
-(void) responseCapability: (NSArray *) tokens;

@end
