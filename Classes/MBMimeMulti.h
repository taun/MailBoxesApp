//
//  MBMimeMulti.h
//  MailBoxes
//
//  Created by Taun Chapman on 12/2/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MBMime.h"


@interface MBMimeMulti : MBMime

@property (nonatomic, retain) NSString * boundary;

@end
