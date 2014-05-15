//
//  MBMimeMessage.h
//  MailBoxes
//
//  Created by Taun Chapman on 05/12/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MBMime.h"

@class MBMessage;

@interface MBMimeMessage : MBMime

@property (nonatomic, retain) MBMessage *subMessage;

@end
