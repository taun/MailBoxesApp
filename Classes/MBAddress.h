//
//  MBAddress.h
//  MailBoxes
//
//  Created by Taun Chapman on 03/20/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MBAddress, MBAddressList, MBMessage;

@interface MBAddress : NSManagedObject

@property (nonatomic, retain) NSString * addressBookURI;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSNumber * isLeaf;
@property (nonatomic, retain) NSSet *parentNodes;
@property (nonatomic, retain) NSSet *childNodes;
@property (nonatomic, retain) NSSet *messagesBcc;
@property (nonatomic, retain) NSSet *messagesCc;
@property (nonatomic, retain) NSSet *messagesFrom;
@property (nonatomic, retain) NSSet *messagesReplyTo;
@property (nonatomic, retain) NSSet *messagesSender;
@property (nonatomic, retain) NSSet *messagesTo;
@property (nonatomic, retain) NSSet *list;
@end

@interface MBAddress (CoreDataGeneratedAccessors)

- (void)addParentNodesObject:(MBAddress *)value;
- (void)removeParentNodesObject:(MBAddress *)value;
- (void)addParentNodes:(NSSet *)values;
- (void)removeParentNodes:(NSSet *)values;

- (void)addChildNodesObject:(MBAddress *)value;
- (void)removeChildNodesObject:(MBAddress *)value;
- (void)addChildNodes:(NSSet *)values;
- (void)removeChildNodes:(NSSet *)values;

- (void)addMessagesBccObject:(MBMessage *)value;
- (void)removeMessagesBccObject:(MBMessage *)value;
- (void)addMessagesBcc:(NSSet *)values;
- (void)removeMessagesBcc:(NSSet *)values;

- (void)addMessagesCcObject:(MBMessage *)value;
- (void)removeMessagesCcObject:(MBMessage *)value;
- (void)addMessagesCc:(NSSet *)values;
- (void)removeMessagesCc:(NSSet *)values;

- (void)addMessagesFromObject:(MBMessage *)value;
- (void)removeMessagesFromObject:(MBMessage *)value;
- (void)addMessagesFrom:(NSSet *)values;
- (void)removeMessagesFrom:(NSSet *)values;

- (void)addMessagesReplyToObject:(MBMessage *)value;
- (void)removeMessagesReplyToObject:(MBMessage *)value;
- (void)addMessagesReplyTo:(NSSet *)values;
- (void)removeMessagesReplyTo:(NSSet *)values;

- (void)addMessagesSenderObject:(MBMessage *)value;
- (void)removeMessagesSenderObject:(MBMessage *)value;
- (void)addMessagesSender:(NSSet *)values;
- (void)removeMessagesSender:(NSSet *)values;

- (void)addMessagesToObject:(MBMessage *)value;
- (void)removeMessagesToObject:(MBMessage *)value;
- (void)addMessagesTo:(NSSet *)values;
- (void)removeMessagesTo:(NSSet *)values;

- (void)addListObject:(MBAddressList *)value;
- (void)removeListObject:(MBAddressList *)value;
- (void)addList:(NSSet *)values;
- (void)removeList:(NSSet *)values;

@end
