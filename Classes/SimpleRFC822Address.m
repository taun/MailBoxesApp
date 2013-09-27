//
//  SimpleRFC822Address.m
//  MailBoxes
//
//  Created by Taun Chapman on 11/1/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import "SimpleRFC822Address.h"

@implementation SimpleRFC822Address

@synthesize name, email, mailbox, domain;


-(NSString *) stringRFC822AddressFormat {
    NSString *rfc822Email = nil;
    if (self.name.length != 0) {
        rfc822Email = [NSString stringWithFormat: @"%@ <%@>", self.name, self.email];
    } else {
        rfc822Email = [NSString stringWithFormat: @"<%@>", self.email];
    }
    return rfc822Email;
}

-(NSString*) description {
    return [NSString stringWithFormat:@"%@ Name: %@; E-Mail: %@;", [super description], self.name, self.email];
}

@end
