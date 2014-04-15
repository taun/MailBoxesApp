//
//  MBViewPortalSelection+Extra.m
//  MailBoxes
//
//  Created by Taun Chapman on 02/24/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBViewPortalSelection+Extra.h"
#import "MBox+IMAP.h"
#import "MBAccount+IMAP.h"
#import "MBAccountsCoordinator.h"

@implementation MBViewPortalSelection (Extra)

+ (NSString *)entityName {
    return @"MBViewPortalSelection";
}


+(NSString*) classTitle {
    return @"Selection";
}

-(void) updateItemsList {
    MBox* mbox = (MBox*)self.messageArraySource;
    MBAccount* account = mbox.accountReference;
    MBAccountsCoordinator* accountCoord = [MBAccountsCoordinator sharedInstanceForUser: account.user];
    [accountCoord updateLatestMessagesForAccount: account mbox: mbox olderThan: 7*24*60*60];
    
}

@end
