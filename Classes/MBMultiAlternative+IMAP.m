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
    
    NSOrderedSet* subNodes = self.childNodes;
    
    MBMime* plainText;
    MBMime* richNode; // can be html or enriched
    
    for (MBMime* node in subNodes) {
        // should only be two nodes, use an assert?
        // could also just check the first node
        // rather than depend on the order of childnodes, let's find the plain text alternative.
        if ([node.type isEqualToString:@"TEXT"] && [node.subtype isEqualToString: @"PLAIN"]) {
            plainText = node;
        } else {
            richNode = node;
        }
    }
    
    MBMime* node = [self hasRichMessageViewOption: options] ? richNode : plainText;

    NSAttributedString* returnString = [node asAttributedStringWithOptions: options attributes: attributes];
    
    return returnString;
}

@end
