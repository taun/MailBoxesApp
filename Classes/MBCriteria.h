//
//  MBCriteria.h
//  MailBoxes
//
//  Created by Taun Chapman on 8/24/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MBPortal, MBox;

@interface MBCriteria : NSManagedObject {
@private
}
@property (nonatomic, strong) NSString * criteria;
@property (nonatomic, strong) NSString * descriptor;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) MBox *mbox;
@property (nonatomic, strong) MBPortal *portals;

@end
