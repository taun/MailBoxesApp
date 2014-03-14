//
//  IMAPPortal.m
//  MailBoxes
//
//  Created by Taun Chapman on 05/06/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import "MBPortal+IMAP.h"


@implementation MBPortal (IMAP)

+ (NSString *)entityName {
    return @"MBPortal";
}


+ (NSArray *)keysToBeCopied {
    static NSArray *keysToBeCopied = nil;
    if (keysToBeCopied == nil) {
        keysToBeCopied = @[@"name", @"desc", @"position", @"predicate"];
    }
    return keysToBeCopied;
}

// Test

@end
