//
//  MBViewPortal.h
//  MailBoxes
//
//  Created by Taun Chapman on 11/14/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MBTreeNode, MBUser;

@interface MBViewPortal : NSManagedObject

@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) MBTreeNode *messageArraySource;
@property (nonatomic, retain) MBUser *user;

@end
