//
//  IMAPDataStore.h
//  MailBoxes
//
//  Created by Taun Chapman on 12/1/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
@class MBMessage;
@class MBox;

/*!
 Currently only one implementor of the IMAPDataStore protocol, IMAPCoreDataStore.
 
 Intent is to allow other protocol implementors to allow other non Core Data persistance mechanisms.
 */

@protocol IMAPDataStore <NSObject>

@property (nonatomic,strong) MBox                  *selectedMBox;

-(MBox *) selectMailBox: (NSString *) fullPath;

-(void) save;

-(MBMessage*) messageForObjectID: (NSManagedObjectID*) messageID;

-(NSNumber*) lowestUID;

-(NSSet*) allUIDsForSelectedMailBox;

-(NSSet*) allCachedUIDsForSelectedMailBox;

-(NSSet*) allCachedUIDsNotFullyCachedForSelectedMailBox;

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
 
 @param fullPath NSString
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
 Work on the messages in the selectedMBox. Check for an existing message with uid first.
 
 @param uid NSNumber
 @param aDictionary NSDictionary
 */
-(BOOL) setMessage: (NSNumber*) uid propertiesFromDictionary: (NSDictionary*) aDictionary;
/*!
 Do not check for existing message. Just create a new message.
 
 @param uid
 @param aDictionary
 
 @return 
 */
-(BOOL) newMessage: (NSNumber*) uid propertiesFromDictionary: (NSDictionary*) aDictionary;

@end
