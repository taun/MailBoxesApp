//
//  MBAttachment.h
//  MailBoxes
//
//  Created by Taun Chapman on 11/14/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MBMessage;

@interface MBAttachment : NSManagedObject

@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSData * raw;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) MBMessage *message;

@end
