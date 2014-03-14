//
//  MBMimeImage+DataTransforms.m
//  MailBoxes
//
//  Created by Taun Chapman on 10/07/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBMimeImage+IMAP.h"
#import "MBMime+IMAP.h"

@implementation MBMimeImage (IMAP)

+ (NSString *)entityName {
    return @"MBMimeImage";
}



#pragma message "ToDo: check for base64 encoding before decoding using base64"
-(void) decoder {
    if (self.data.encoded != nil) {
        NSData* decoded = [[NSData alloc] initWithBase64EncodedString: self.data.encoded options: NSDataBase64DecodingIgnoreUnknownCharacters];
        if (decoded) {
            self.data.decoded = decoded;
            self.data.isDecoded = @YES;
        }
    }
    
}

-(NSAttributedString*) asAttributedStringWithOptions:(NSDictionary *)options attributes: (NSDictionary*) attributes {
    NSData* nsData = [self getDecodedData];
    
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
