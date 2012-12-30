//
//  MBFlag.h
//  MailBoxes
//
//  Created by Taun Chapman on 11/14/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MBMessage;

@interface MBFlag : NSManagedObject

@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * serverAssignedName;
@property (nonatomic, retain) NSString * userAssignedName;
@property (nonatomic, retain) NSSet *messages;
@end

@interface MBFlag (CoreDataGeneratedAccessors)

- (void)addMessagesObject:(MBMessage *)value;
- (void)removeMessagesObject:(MBMessage *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

@end
