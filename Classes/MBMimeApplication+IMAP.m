//
//  MBMimeApplication+IMAP.m
//  MailBoxes
//
//  Created by Taun Chapman on 10/08/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBMimeApplication+IMAP.h"
#import "MBMime+IMAP.h"
#import <Quartz/Quartz.h>

NSString* attachmentIconName = @"attach_48.png";

@implementation MBMimeApplication (IMAP)

/*!
 Need to decode data based on the subtype.
 Subtypes can be
    PDF
    MSWORD
    ??
 */
-(NSAttributedString*) asAttributedStringWithOptions:(NSDictionary *)options attributes: (NSDictionary*) attributes {
    NSAttributedString* returnString;
    
    if ([self.subtype isEqualToString: @"PDF"]) {
        returnString = [self pdfAsAttributedStringWithOptions:options attributes:attributes];
        
    } else  if ([self.subtype isEqualToString: @"MSWORD"]) {
        returnString = [self mswordAsAttributedStringWithOptions:options attributes:attributes];
        
    } else {
        returnString = [self unknownAsAttributedStringWithOptions:options attributes:attributes];
    }
    
    return returnString;
}

-(NSAttributedString*) pdfAsAttributedStringWithOptions:(NSDictionary *)options attributes: (NSDictionary*) attributes {
    NSAttributedString* returnString;
    NSData* nsData = [[NSData alloc] initWithBase64Encoding: self.data.encoded];

    PDFDocument* document = [[PDFDocument alloc] initWithData: nsData];

    if ([self.isInline boolValue] == YES) {
        // as attachment
        returnString = [self createAttachmentWithData: nsData imageName: attachmentIconName name: self.name attributes: attributes];
    } else {
        // inline
        returnString = [[NSAttributedString alloc] initWithString: document.string attributes: attributes];
    }
    
    return returnString;
}
-(NSAttributedString*) mswordAsAttributedStringWithOptions:(NSDictionary *)options attributes: (NSDictionary*) attributes {
    NSAttributedString* returnString;
    NSData* nsData = [[NSData alloc] initWithBase64Encoding: self.data.encoded];
    
    if ([self.isInline boolValue] == NO) {
        // as attachment
        returnString = [self createAttachmentWithData: nsData imageName: attachmentIconName name: self.name attributes: attributes];
    } else {
        // inline
        returnString = [[NSAttributedString alloc] initWithDocFormat: nsData documentAttributes: &attributes];
    }
    
    return returnString;
}
-(NSAttributedString*) unknownAsAttributedStringWithOptions:(NSDictionary *)options attributes: (NSDictionary*) attributes {
    NSAttributedString* returnString;
    NSData* nsData = [[NSData alloc] initWithBase64Encoding: self.data.encoded];
    
    if ([self.isInline boolValue] == NO) {
        // as attachment
        returnString = [self createAttachmentWithData: nsData imageName: attachmentIconName name: self.name attributes: attributes];
    } else {
        // inline
        returnString = [[NSAttributedString alloc] initWithData: nsData options: nil documentAttributes: &attributes error: nil];
    }
    
    return returnString;
}

-(NSAttributedString*) createAttachmentWithData: (NSData*) data imageName: (NSString*) image name: (NSString*) name attributes: (NSDictionary*) attributes {
    NSImage* attachmentImage = [NSImage imageNamed: image];
    
    NSTextAttachmentCell *attachmentCell = [[NSTextAttachmentCell alloc] initImageCell: attachmentImage];
    attachmentCell.identifier = name;
    
    NSFileWrapper* file = [[NSFileWrapper alloc] initRegularFileWithContents: data];
    [file setPreferredFilename: name];
    [file setFilename: name];
    
    NSTextAttachment* attachment = [[NSTextAttachment alloc] initWithFileWrapper: file];
    
    [attachment setAttachmentCell: attachmentCell];
    [attachment.fileWrapper setPreferredFilename: self.name];
    
    NSMutableAttributedString* attachmentString = [[NSAttributedString attributedStringWithAttachment: attachment] mutableCopy];
    [attachmentString appendAttributedString: [[NSAttributedString alloc] initWithString: self.name attributes: attributes]];
    return [attachmentString copy];
}

@end
