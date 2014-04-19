//
//  MBViewPortalMBox+Extra.m
//  MailBoxes
//
//  Created by Taun Chapman on 02/24/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBViewPortalMBox+Extra.h"
#import "MBox+IMAP.h"
#import "MBAccount+IMAP.h"
#import "MBAccountsCoordinator.h"

@implementation MBViewPortalMBox (Extra)

+ (NSString *)entityName {
    return @"MBViewPortalMBox";
}


+(NSString*) classTitle {
    return @"MailBox";
}

-(void) updateItemsList {
    MBox* mbox = (MBox*)self.messageArraySource;
    MBAccount* account = mbox.accountReference;
    MBAccountsCoordinator* accountCoord = [MBAccountsCoordinator sharedInstanceForUser: account.user];
    [accountCoord updateLatestMessagesForAccount: account mbox: mbox];

}
@end
