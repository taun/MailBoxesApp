//
//  MBSidebar.h
//  MailBoxes
//
//  Created by Taun Chapman on 03/11/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MBTreeNode.h"

@class MBUser;

@interface MBSidebar : MBTreeNode

@property (nonatomic, retain) MBUser *user;

@end
