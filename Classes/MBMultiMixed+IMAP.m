//
//  MBMultiMixed+IMAP.m
//  MailBoxes
//
//  Created by Taun Chapman on 10/08/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBMultiMixed+IMAP.h"
#import "MBMime+IMAP.h"

@implementation MBMultiMixed (IMAP)

-(NSAttributedString*) asAttributedStringWithOptions:(NSDictionary *)options attributes:(NSDictionary *)attributes {
    NSMutableAttributedString* composition = [[NSMutableAttributedString alloc] initWithString: @"" attributes: attributes];
    
    for (MBMime* node in self.childNodes) {
        NSAttributedString* nodeComposition = [node asAttributedStringWithOptions: options attributes: attributes];
        [composition appendAttributedString: nodeComposition];
    }
    
    return [composition copy];
}

@end
