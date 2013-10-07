//
//  MBMultiAlternative+IMAP.m
//  MailBoxes
//
//  Created by Taun Chapman on 10/07/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBMultiAlternative+IMAP.h"
#import "MBMime+IMAP.h"


@implementation MBMultiAlternative (IMAP)

-(NSAttributedString*) asAttributedStringWithOptions:(NSDictionary *)options attributes: (NSDictionary*) attributes {
    
    BOOL useRichMessageView = NO;
    id useRichMessageViewOption = [options objectForKey: MBRichMessageViewAttributeName];
    
    if (useRichMessageViewOption && [useRichMessageViewOption isKindOfClass: [NSNumber class]]) {
        useRichMessageView = [(NSNumber*)useRichMessageViewOption boolValue];
    }

    NSData* nsData = [self.data.encoded dataUsingEncoding: NSASCIIStringEncoding];

    NSAttributedString* returnString = [[NSAttributedString alloc] initWithData: nsData options: nil documentAttributes: &attributes error: nil];
    
    return returnString;
}

@end
