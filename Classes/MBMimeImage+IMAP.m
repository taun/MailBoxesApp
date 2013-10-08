//
//  MBMimeImage+DataTransforms.m
//  MailBoxes
//
//  Created by Taun Chapman on 10/07/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBMimeImage+IMAP.h"
#import "MBMime+IMAP.h"

@implementation MBMimeImage (DataTransforms)

-(NSAttributedString*) asAttributedStringWithOptions:(NSDictionary *)options attributes: (NSDictionary*) attributes {
    NSData* nsData = [[NSData alloc] initWithBase64Encoding: self.data.encoded];
    
    NSImage* messageImage = [[NSImage alloc] initWithData: nsData];
    NSTextAttachmentCell *anAttachmentCell = [[NSTextAttachmentCell
                                               alloc] initImageCell: messageImage];
    
    //[anAttachmentCell setTitle: self.name];
    
    NSTextAttachment* attachment = [[NSTextAttachment alloc] init];
    
    [attachment setAttachmentCell: anAttachmentCell];
    [attachment.fileWrapper setPreferredFilename: self.name];
    
    NSAttributedString* returnString = [NSAttributedString attributedStringWithAttachment: attachment];
    
    return returnString;
}

@end
