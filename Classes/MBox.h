//
//  MBox.h
//  MailBoxes
//
//  Created by Taun Chapman on 03/11/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MBTreeNode.h"

@class MBAccount, MBFlag, MBMessage;

@interface MBox : MBTreeNode

@property (nonatomic, retain) NSString * fullPath;
@property (nonatomic, retain) NSNumber * isMarked;
@property (nonatomic, retain) NSNumber * isReadWrite;
@property (nonatomic, retain) NSNumber * lastSeenUID;
@property (nonatomic, retain) NSDate * lastSelected;
@property (nonatomic, retain) NSDate * lastSync;
@property (nonatomic, retain) NSString * pathSeparator;
@property (nonatomic, retain) NSNumber * serverHighestModSeq;
@property (nonatomic, retain) NSNumber * serverMessages;
@property (nonatomic, retain) NSNumber * serverRecent;
@property (nonatomic, retain) NSNumber * serverUIDNext;
@property (nonatomic, retain) NSNumber * serverUIDValidity;
@property (nonatomic, retain) NSNumber * serverUnseen;
@property (nonatomic, retain) NSString * specialUse;
@property (nonatomic, retain) NSString * uid;
@property (nonatomic, retain) MBAccount *accountReference;
@property (nonatomic, retain) NSSet *availableFlags;
@property (nonatomic, retain) MBMessage *lastChangedMessage;
@property (nonatomic, retain) NSSet *messages;
@property (nonatomic, retain) NSSet *permanentFlags;
@end

@interface MBox (CoreDataGeneratedAccessors)

- (void)addAvailableFlagsObject:(MBFlag *)value;
- (void)removeAvailableFlagsObject:(MBFlag *)value;
- (void)addAvailableFlags:(NSSet *)values;
- (void)removeAvailableFlags:(NSSet *)values;

- (void)addMessagesObject:(MBMessage *)value;
- (void)removeMessagesObject:(MBMessage *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

- (void)addPermanentFlagsObject:(MBFlag *)value;
- (void)removePermanentFlagsObject:(MBFlag *)value;
- (void)addPermanentFlags:(NSSet *)values;
- (void)removePermanentFlags:(NSSet *)values;

@end
