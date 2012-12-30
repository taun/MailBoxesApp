//
//  MBViewPortalSelection.h
//  MailBoxes
//
//  Created by Taun Chapman on 11/14/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MBViewPortal.h"

@class MBTreeNode;

@interface MBViewPortalSelection : MBViewPortal

@property (nonatomic, retain) MBTreeNode *messages;

@end
