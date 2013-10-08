//
//  MBMimeText+IMAP.m
//  MailBoxes
//
//  Created by Taun Chapman on 10/08/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBMimeText+IMAP.h"
#import "MBMime+IMAP.h"

@implementation MBMimeText (IMAP)

/*!
 Need to decode data based on the subtype.
 Subtypes can be
    PLAIN
    ENRICHED
    HTML
 */
-(NSAttributedString*) asAttributedStringWithOptions:(NSDictionary *)options attributes: (NSDictionary*) attributes {
    NSAttributedString* returnString;
    
    if ([self.subtype isEqualToString: @"PLAIN"]) {
        returnString = [self plainAsAttributedStringWithOptions:options attributes:attributes];
        
    } else  if ([self.subtype isEqualToString: @"ENRICHED"]) {
        returnString = [self enrichedAsAttributedStringWithOptions:options attributes:attributes];
        
    } else if ([self.subtype isEqualToString: @"HTML"]) {
        returnString = [self htmlAsAttributedStringWithOptions:options attributes:attributes];
    }
    
    return returnString;
}

-(NSAttributedString*) plainAsAttributedStringWithOptions:(NSDictionary *)options attributes: (NSDictionary*) attributes {
    NSData* nsData = [self.data.encoded dataUsingEncoding: NSASCIIStringEncoding];
    
    NSAttributedString* returnString = [[NSAttributedString alloc] initWithData: nsData options: nil documentAttributes: &attributes error: nil];
    
    return returnString;
}
-(NSAttributedString*) htmlAsAttributedStringWithOptions:(NSDictionary *)options attributes: (NSDictionary*) attributes {
    NSData* nsData = [self.data.encoded dataUsingEncoding: NSASCIIStringEncoding];
    
    NSAttributedString* returnString = [[NSAttributedString alloc] initWithHTML: nsData documentAttributes: &attributes];
    
    return returnString;
}
-(NSAttributedString*) enrichedAsAttributedStringWithOptions:(NSDictionary *)options attributes: (NSDictionary*) attributes {
    NSData* nsData = [self.data.encoded dataUsingEncoding: NSASCIIStringEncoding];
    
    NSAttributedString* returnString = [[NSAttributedString alloc] initWithData: nsData options: nil documentAttributes: &attributes error: nil];
    
    return returnString;
}

@end
