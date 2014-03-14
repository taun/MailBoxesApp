//
//  MBMimeData.h
//  MailBoxes
//
//  Created by Taun Chapman on 03/11/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MBMime;

@interface MBMimeData : NSManagedObject

@property (nonatomic, retain) NSData * decoded;
@property (nonatomic, retain) NSString * encoded;
@property (nonatomic, retain) NSString * encoding;
@property (nonatomic, retain) NSNumber * isDecoded;
@property (nonatomic, retain) MBMime *mimeStructure;

@end
