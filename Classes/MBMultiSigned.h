//
//  MBMultiSigned.h
//  MailBoxes
//
//  Created by Taun Chapman on 12/2/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MBMimeMulti.h"


@interface MBMultiSigned : MBMimeMulti

@property (nonatomic, retain) NSString * micalg;
@property (nonatomic, retain) NSString * protocol;

@end
