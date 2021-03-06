//
//  MBDispositionParameter.h
//  MailBoxes
//
//  Created by Taun Chapman on 03/11/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MBMimeDisposition;

@interface MBDispositionParameter : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * value;
@property (nonatomic, retain) MBMimeDisposition *disposition;

@end
