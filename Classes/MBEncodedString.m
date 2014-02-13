//
//  MBEncodedString.m
//  MailBoxes
//
//  Created by Taun Chapman on 02/11/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBEncodedString.h"

@implementation MBEncodedString

+(instancetype) encodedString:(NSString *)string encoding:(NSStringEncoding)encoding {
    return [[[self class] alloc] initWithString: string encoding: encoding];
}

- (id)initWithString:(NSString *)string encoding:(NSStringEncoding)encoding {
    self = [super init];
    if (self) {
        _string = string;
        _encoding = encoding;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone{
    return [MBEncodedString encodedString: _string encoding: _encoding];
}

-(NSData*) asData {
    return [self.string dataUsingEncoding: self.encoding];
}

@end