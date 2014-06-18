//
//  MBMimeMessage+IMAP.m
//  MailBoxes
//
//  Created by Taun Chapman on 05/12/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBMimeMessage+IMAP.h"
#import "MBMime+IMAP.h"
#import "MBMessage+IMAP.h"
#import "MBAddress+IMAP.h"
#import "NSManagedObject+Shortcuts.h"

#import <MoedaeMailPlugins/MoedaeMailPlugins.h>

@implementation MBMimeMessage (IMAP)

/*!
 Override allChildNodes because the childNodes are part of the subMessage not the message mime.
 The message is a self contained node of the message/rfc822 mime object.
 
 @return all of the message childNodes.
 */
-(NSSet*) allChildNodes {
    NSMutableSet* _allChildNodes = [NSMutableSet setWithCapacity: self.childNodes.count];
    
    for (MBMime* node in self.subMessage.childNodes) {
        [_allChildNodes unionSet: [node allChildNodes]];
    }
    
    [_allChildNodes addObject: self];
    return [_allChildNodes copy];
}
-(NSOrderedSet*) mappedChildNodes {
    return self.subMessage.childNodes;
}

-(MMPMimeProxy*) asMimeProxy {
    MMPMimeProxy* proxy = [super asMimeProxy];
    proxy.subject = self.subMessage.subject;
    proxy.addressSender = [self.subMessage.addressSender newSimpleAddress];
    proxy.addressFrom = [self.subMessage.addressFrom newSimpleAddress];
    proxy.addressesTo = [self.subMessage.addressesTo newSimpleAddress];
    proxy.addressReplyTo = [self.subMessage.addressReplyTo newSimpleAddress];
    
    return proxy;
}
@end
