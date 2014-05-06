//
//  MBox+IMAP.h
//  MailBoxes
//
//  Created by Taun Chapman on 2/24/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBox.h"

@class MBFlag;
@class MBoxProxy;

#define MBoxImageName @"folder_16"

/*!
 @header
 
 more later
 
 */

/*!
 @category MBox(IMAP)
 
 At some point, the goal is to have each mailbox refresh itself rather
 than the account deleting everything and starting over.
 The mbox tree should be able to do a recursive refresh working down to
 the leaves. Each box would check whether it still exists, was renamed, ...
 The leaves would then send refresh to the messages?
 
 */
@interface MBox (IMAP)

/*!
 Discussion
 
 @param uid the message Unique Identifier
 @param create BOOL flag to create the message if it does not exist
 
 @result the new MBMessage node in the MBox or nil if there was a problem.
 */
- (MBMessage *)getMBMessageWithUID:(NSNumber *)uid 
                   createIfMissing:(BOOL)create;
- (MBMessage *)newMBMessageWithUID:(NSNumber *)uid;

/*!
 Empties the mail box but does not save the context.
 Messages are not really gone until the context is saved.
 */
- (void)removeAllCachedMessages;

- (MBFlag *)getMBFlagWithServerAssignedName: (NSString *) serverName 
                             createIfMissing:(BOOL)create;

- (MBFlag *) findFlagForServerName: (NSString *) serverName;

- (NSSet*) allUIDS;

- (NSSet*) allUIDSForNotFullyCached;

- (NSNumber*) lowestUID;

- (void)encodeWithCoder:(NSCoder *)coder;

- (id)initWithCoder: (NSCoder *)coder;

-(MBoxProxy*) asMBoxProxy;

@end
