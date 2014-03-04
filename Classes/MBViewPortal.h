//
//  MBViewPortal.h
//  MailBoxes
//
//  Created by Taun Chapman on 03/03/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MBTreeNode, MBUser;

@interface MBViewPortal : NSManagedObject

@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * rowHeight;
@property (nonatomic, retain) id color;
@property (nonatomic, retain) MBTreeNode *messageArraySource;
@property (nonatomic, retain) MBUser *user;

@end
