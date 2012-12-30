//
//  MBAddress.h
//  MailBoxes
//
//  Created by Taun Chapman on 11/14/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MBMessage;

@interface MBAddress : NSManagedObject

@property (nonatomic, retain) NSString * addressBookURI;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *messagesBcc;
@property (nonatomic, retain) NSSet *messagesCc;
@property (nonatomic, retain) NSSet *messagesFrom;
@property (nonatomic, retain) MBMessage *messagesReplyTo;
@property (nonatomic, retain) NSSet *messagesSender;
@property (nonatomic, retain) NSSet *messagesTo;
@end

@interface MBAddress (CoreDataGeneratedAccessors)

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

- (void)addMessagesSenderObject:(MBMessage *)value;
- (void)removeMessagesSenderObject:(MBMessage *)value;
- (void)addMessagesSender:(NSSet *)values;
- (void)removeMessagesSender:(NSSet *)values;

- (void)addMessagesToObject:(MBMessage *)value;
- (void)removeMessagesToObject:(MBMessage *)value;
- (void)addMessagesTo:(NSSet *)values;
- (void)removeMessagesTo:(NSSet *)values;

@end
