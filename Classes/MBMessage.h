//
//  MBMessage.h
//  MailBoxes
//
//  Created by Taun Chapman on 12/20/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MBAddress, MBAttachment, MBFlag, MBLabel, MBMime, MBRFC2822, MBox;

@interface MBMessage : NSManagedObject

@property (nonatomic, retain) NSDate * dateReceived;
@property (nonatomic, retain) NSDate * dateSent;
@property (nonatomic, retain) NSString * encoding;
@property (nonatomic, retain) NSNumber * isAnsweredFlag;
@property (nonatomic, retain) NSNumber * isDeletedFlag;
@property (nonatomic, retain) NSNumber * isDraftFlag;
@property (nonatomic, retain) NSNumber * isFlaggedFlag;
@property (nonatomic, retain) NSNumber * isFullyCached;
@property (nonatomic, retain) NSNumber * isRecentFlag;
@property (nonatomic, retain) NSNumber * isSeenFlag;
@property (nonatomic, retain) NSString * messageId;
@property (nonatomic, retain) NSString * organization;
@property (nonatomic, retain) NSNumber * rfc2822Size;
@property (nonatomic, retain) NSNumber * sequence;
@property (nonatomic, retain) NSString * subject;
@property (nonatomic, retain) NSString * summary;
@property (nonatomic, retain) NSNumber * uid;
@property (nonatomic, retain) NSNumber * hasAttachment;
@property (nonatomic, retain) NSSet *addressesBcc;
@property (nonatomic, retain) NSSet *addressesCc;
@property (nonatomic, retain) NSSet *addressesTo;
@property (nonatomic, retain) MBAddress *addressFrom;
@property (nonatomic, retain) MBAddress *addressReplyTo;
@property (nonatomic, retain) MBAddress *addressSender;
@property (nonatomic, retain) NSSet *allParts;
@property (nonatomic, retain) NSSet *attachments;
@property (nonatomic, retain) NSOrderedSet *childNodes;
@property (nonatomic, retain) NSSet *flags;
@property (nonatomic, retain) MBLabel *labels;
@property (nonatomic, retain) MBox *lastChanged;
@property (nonatomic, retain) MBox *mbox;
@property (nonatomic, retain) MBRFC2822 *rfc2822;
@end

@interface MBMessage (CoreDataGeneratedAccessors)

- (void)addAddressesBccObject:(MBAddress *)value;
- (void)removeAddressesBccObject:(MBAddress *)value;
- (void)addAddressesBcc:(NSSet *)values;
- (void)removeAddressesBcc:(NSSet *)values;

- (void)addAddressesCcObject:(MBAddress *)value;
- (void)removeAddressesCcObject:(MBAddress *)value;
- (void)addAddressesCc:(NSSet *)values;
- (void)removeAddressesCc:(NSSet *)values;

- (void)addAddressesToObject:(MBAddress *)value;
- (void)removeAddressesToObject:(MBAddress *)value;
- (void)addAddressesTo:(NSSet *)values;
- (void)removeAddressesTo:(NSSet *)values;

- (void)addAllPartsObject:(MBMime *)value;
- (void)removeAllPartsObject:(MBMime *)value;
- (void)addAllParts:(NSSet *)values;
- (void)removeAllParts:(NSSet *)values;

- (void)addAttachmentsObject:(MBAttachment *)value;
- (void)removeAttachmentsObject:(MBAttachment *)value;
- (void)addAttachments:(NSSet *)values;
- (void)removeAttachments:(NSSet *)values;

- (void)insertObject:(MBMime *)value inChildNodesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromChildNodesAtIndex:(NSUInteger)idx;
- (void)insertChildNodes:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeChildNodesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInChildNodesAtIndex:(NSUInteger)idx withObject:(MBMime *)value;
- (void)replaceChildNodesAtIndexes:(NSIndexSet *)indexes withChildNodes:(NSArray *)values;
- (void)addChildNodesObject:(MBMime *)value;
- (void)removeChildNodesObject:(MBMime *)value;
- (void)addChildNodes:(NSOrderedSet *)values;
- (void)removeChildNodes:(NSOrderedSet *)values;
- (void)addFlagsObject:(MBFlag *)value;
- (void)removeFlagsObject:(MBFlag *)value;
- (void)addFlags:(NSSet *)values;
- (void)removeFlags:(NSSet *)values;

@end
