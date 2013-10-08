//
//  MBMimeApplication+IMAP.m
//  MailBoxes
//
//  Created by Taun Chapman on 10/08/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBMimeApplication+IMAP.h"
#import "MBMime+IMAP.h"


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
    
    if (YES) {
        // as attachment
        NSImage* attachmentImage = [NSImage imageNamed: attachmentIconName];
        NSTextAttachmentCell *anAttachmentCell = [[NSTextAttachmentCell
                                                   alloc] initImageCell: attachmentImage];
        
        //[anAttachmentCell setTitle: self.name];
        
        NSTextAttachment* attachment = [[NSTextAttachment alloc] init];
        
        [attachment setAttachmentCell: anAttachmentCell];
        [attachment.fileWrapper setPreferredFilename: self.name];
        
        returnString = [NSAttributedString attributedStringWithAttachment: attachment];
    } else {
        // inline
        NSData* nsData = [self.data.encoded dataUsingEncoding: NSASCIIStringEncoding];
        returnString = [[NSAttributedString alloc] initWithData: nsData options: nil documentAttributes: &attributes error: nil];
    }
    
    return returnString;
}
-(NSAttributedString*) mswordAsAttributedStringWithOptions:(NSDictionary *)options attributes: (NSDictionary*) attributes {
    NSAttributedString* returnString;
    
    if (YES) {
        // as attachment
        NSImage* attachmentImage = [NSImage imageNamed: attachmentIconName];
        NSTextAttachmentCell *anAttachmentCell = [[NSTextAttachmentCell
                                                   alloc] initImageCell: attachmentImage];
        
        //[anAttachmentCell setTitle: self.name];
        
        NSTextAttachment* attachment = [[NSTextAttachment alloc] init];
        
        [attachment setAttachmentCell: anAttachmentCell];
        [attachment.fileWrapper setPreferredFilename: self.name];
        
        returnString = [NSAttributedString attributedStringWithAttachment: attachment];
    } else {
        // inline
        NSData* nsData = [self.data.encoded dataUsingEncoding: NSASCIIStringEncoding];
        returnString = [[NSAttributedString alloc] initWithDocFormat: nsData documentAttributes: &attributes];
    }
    
    return returnString;
}
-(NSAttributedString*) unknownAsAttributedStringWithOptions:(NSDictionary *)options attributes: (NSDictionary*) attributes {
    NSAttributedString* returnString;
    
    if (YES) {
        // as attachment
        NSImage* attachmentImage = [NSImage imageNamed: attachmentIconName];
        NSTextAttachmentCell *anAttachmentCell = [[NSTextAttachmentCell
                                                   alloc] initImageCell: attachmentImage];
        
        //[anAttachmentCell setTitle: self.name];
        
        NSTextAttachment* attachment = [[NSTextAttachment alloc] init];
        
        [attachment setAttachmentCell: anAttachmentCell];
        [attachment.fileWrapper setPreferredFilename: self.name];
        
        returnString = [NSAttributedString attributedStringWithAttachment: attachment];
    } else {
        // inline
        NSData* nsData = [self.data.encoded dataUsingEncoding: NSASCIIStringEncoding];
        returnString = [[NSAttributedString alloc] initWithData: nsData options: nil documentAttributes: &attributes error: nil];
    }
    
    return returnString;
}


@end
