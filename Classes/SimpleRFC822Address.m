//
//  SimpleRFC822Address.m
//  MailBoxes
//
//  Created by Taun Chapman on 11/1/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import "SimpleRFC822Address.h"

@implementation SimpleRFC822Address

+(instancetype) newAddressName:(NSString *)name email:(NSString *)email {
    return [[SimpleRFC822Address alloc] initWithName:name email:email];
}

/* designated initializer */
-(instancetype) initWithName:(NSString *)name email:(NSString *)email {
    self = [super init];
    
    if (self) {
        _name = name;
        _email = email;
        if (email) {
            NSArray* parts = [email componentsSeparatedByString: @"@"];
            if ([parts count]==2) {
                _mailbox = parts[0];
                _domain = parts[1];
            }
        }
    }
    
    return self;
}

-(id) init {
    self = [self initWithName: nil email: nil];
    
    return self;
}

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
    return [NSString stringWithFormat:@"%@ Name: %@; E-Mail: %@; Mailbox: %@; Domain: %@;",
            [super description], self.name, self.email, self.mailbox, self.domain];
}
-(NSString*) debugDescription {
    return [NSString stringWithFormat:@"%@ Name: %@; E-Mail: %@; Mailbox: %@; Domain: %@;",
            [super description], self.name, self.email, self.mailbox, self.domain];
}

- (NSUInteger)hash {
    NSString* fullAddress = [NSString stringWithFormat:@"%@ %@ %@ %@", _name, _email, _mailbox, _domain];
    return [fullAddress hash];
}

- (BOOL)isEqual:(id)other {
    BOOL equality = NO;
    
    if (other == self)
        return YES;
    
    if ([self name]) {
        // if self.name is non-nil then other.name should be non-nil and equal to be an equal object.
        equality = [[self name] isEqualToString:[other name]];
    } else if (![other name]){
        // both == nil
        equality = YES; // chance at equality
    }

    if (equality && [[self email] isEqualToString:[other email]]
        && [[self mailbox] isEqualToString:[other mailbox]]
        && [[self domain] isEqualToString:[other domain]]) {
        equality = YES;
    } else {
        equality = NO;
    }
    
    return equality;
}
@end
