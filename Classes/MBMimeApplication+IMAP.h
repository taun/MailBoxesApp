//
//  MBMimeApplication+IMAP.h
//  MailBoxes
//
//  Created by Taun Chapman on 10/08/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBMimeApplication.h"

@interface MBMimeApplication (IMAP)

@end

/*!
 Unused
 
 There are over 30 different subtypes of Mime Application.
 Would like to map a helper to a subtype rather than 30 application subclasses.
 Basically need a plugin for application subtype rendering.
 */
@protocol MBMimeApplicationHelper <NSObject>

-(NSAttributedString*) asAttributedStringWithOptions:(NSDictionary *)options attributes: (NSDictionary*) attributes;

@end

@interface MBMimeApplicationHelperPDF <MBMimeApplicationHelper>

-(NSAttributedString*) asAttributedStringWithOptions:(NSDictionary *)options attributes: (NSDictionary*) attributes;

@end

@interface MBMimeApplicationHelperMSWord <MBMimeApplicationHelper>

-(NSAttributedString*) asAttributedStringWithOptions:(NSDictionary *)options attributes: (NSDictionary*) attributes;

@end