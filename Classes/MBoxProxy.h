//
//  MBoxProxy.h
//  MailBoxes
//
//  Created by Taun Chapman on 02/18/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const MBPasteboardTypeMbox;

@interface MBoxProxy : NSObject <NSCoding, NSPasteboardReading, NSPasteboardWriting>

@property (nonatomic,strong) NSString       *name;
@property (nonatomic,strong) NSString       *desc;
@property (nonatomic,strong) NSString       *fullPath;
@property (nonatomic,strong) NSString       *uid;
@property (nonatomic,strong) NSURL          *objectURL;
@property (nonatomic,strong) NSString       *accountIdentifier;



@end
