//
//  IMAPPortal.m
//  MailBoxes
//
//  Created by Taun Chapman on 05/06/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import "MBPortal+IMAP.h"


@implementation MBPortal (IMAP)

+ (NSArray *)keysToBeCopied {
    static NSArray *keysToBeCopied = nil;
    if (keysToBeCopied == nil) {
        keysToBeCopied = [[NSArray alloc] initWithObjects:
                          @"name", @"desc", @"position", @"predicate", nil];
    }
    return keysToBeCopied;
}

// Test

@end
