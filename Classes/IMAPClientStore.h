//
//  IMAPClientStore.h
//  MailBoxes
//
//  Created by Taun Chapman on 12/1/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
@class MBMessage;
@class MBox;

@protocol IMAPClientStore <NSObject>

-(MBox *) selectMailBox: (NSString *) fullPath;

-(BOOL) save: (NSError**) error;

-(MBMessage*) messageForObjectID: (NSManagedObjectID*) messageID;

-(NSNumber*) lowestUID;

/*!
 Will need to implement all of the required methods for setting values in the store.
 Maybe as a protocol?
 
 mailbox and message methods
 how to pass arguments?
 
 setMailBox: id name:
 setMailBox: id path:
 setMailBox: id specialUse:
 setMailBox: id permanentFlags:
 setMailBox: id flags:
 setMailBox: id uidvalidity:
 setMailBox: id uidnext:
 
 setMessage: id subject:
 setMessage: id dateReceived:
 setMessage: id rfcsize:
 setMessage: id from:
 setMessage: id to:
 setMessage: id cc:
 setMessage: id bcc:
 setMessage: id raw:
 setMessage: id summary: 
 
 */
-(BOOL) setMailBoxReadOnly: (NSString *) fullPath ;
-(BOOL) setMailBoxReadWrite: (NSString *) fullPath ;
-(BOOL) setMailBoxFlags: (NSArray *) flagTokens onPath:     (NSString *) fullPath withSeparator: (NSString *) aSeparator;

-(BOOL) setMailBox: (NSString *) fullPath       AvailableFlags:     (NSArray *) flagTokens;
-(BOOL) setMailBox: (NSString *) fullPath       PermanentFlags:     (NSArray *) flagTokens;
-(BOOL) setMailBox: (NSString *) fullPath       serverHighestmodseq: (NSNumber *) theCount;
-(BOOL) setMailBox: (NSString *) fullPath       serverMessageCount: (NSNumber *) theCount;
-(BOOL) setMailBox: (NSString *) fullPath       serverRecentCount:  (NSNumber *) theCount;
-(BOOL) setMailBox: (NSString *) fullPath       Uidnext:            (NSNumber *) uidNext;
-(BOOL) setMailBox: (NSString *) fullPath       Uidvalidity:        (NSNumber *) uidValidity;
-(BOOL) setMailBox: (NSString *) fullPath       serverUnseen:       (NSNumber *) unseen;

-(BOOL) selectedMailBoxDeleteAllMessages:  (NSError**) error;


/*!
 All of the following message methods work on the messages in the selectedMBox.
 */
-(BOOL) setMessage: (NSNumber*) uid propertiesFromDictionary: (NSDictionary*) aDictionary;

@end
