//
//  MBRFC2822.h
//  MailBoxes
//
//  Created by Taun Chapman on 11/14/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MBMessage;

@interface MBRFC2822 : NSManagedObject

@property (nonatomic, retain) NSData * raw;
@property (nonatomic, retain) MBMessage *message;

@end
