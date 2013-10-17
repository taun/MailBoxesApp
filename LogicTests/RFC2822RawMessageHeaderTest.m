//
//  RFC2822RawMessageHeaderTest.m
//  MailBoxes
//
//  Created by Taun Chapman on 10/5/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import "RFC2822RawMessageHeaderTest.h"
#import "RFC2822RawMessageHeader.h"
#import "MBMIME2047ValueTransformer.h"
#import "NSString+IMAPConversions.h"
#import "SimpleRFC822Address.h"

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

static const int ddLogLevel = LOG_LEVEL_WARN;


@implementation RFC2822RawMessageHeaderTest
@synthesize testBundle;
@synthesize sampleHeader;
@synthesize rfcRawHeader;

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    
    testBundle = [NSBundle bundleWithIdentifier: @"com.moedae.LogicTests"];
        
    sampleHeader = nil;
    
    rfcRawHeader = nil;
}

- (void)tearDown
{
    // Tear-down code here.
    [super tearDown];
}


-(void) testUnfoldTab {
    NSError *error = nil;
    
    NSString *path = [self.testBundle pathForResource: @"fetchresponse" ofType: @"txt" inDirectory: @"answers"];
    
    self.sampleHeader = [NSString stringWithContentsOfFile: path encoding: NSASCIIStringEncoding error: &error];
    
    self.rfcRawHeader = [[RFC2822RawMessageHeader alloc] initWithString: self.sampleHeader];
    
    DDLogVerbose(@"Unfolded data: \r%@",  self.rfcRawHeader.unfolded);
}

-(void) testFieldsTab {
    NSError *error = nil;
    
    NSString *path = [self.testBundle pathForResource: @"fetchresponse" ofType: @"txt" inDirectory: @"answers"];
    
    self.sampleHeader = [NSString stringWithContentsOfFile: path encoding: NSASCIIStringEncoding error: &error];
    
    self.rfcRawHeader = [[RFC2822RawMessageHeader alloc] initWithString: self.sampleHeader];
    
    DDLogVerbose(@"Fields data: \r%@",  self.rfcRawHeader.fields);
}

-(void) testUnfoldSpace {
    NSError *error = nil;
    
    NSString *path = [self.testBundle pathForResource: @"RFC2822RawHeader" ofType: @"txt" inDirectory: @"answers"];
    
    self.sampleHeader = [NSString stringWithContentsOfFile: path encoding: NSASCIIStringEncoding error: &error];
    
    self.rfcRawHeader = [[RFC2822RawMessageHeader alloc] initWithString: self.sampleHeader];
    
    DDLogVerbose(@"Unfolded data: \r%@",  self.rfcRawHeader.unfolded);
}
-(void) testFieldsSpace {
    NSError *error = nil;
    
    NSString *path = [self.testBundle pathForResource: @"RFC2822RawHeader" ofType: @"txt" inDirectory: @"answers"];
    
    self.sampleHeader = [NSString stringWithContentsOfFile: path encoding: NSASCIIStringEncoding error: &error];
    
    self.rfcRawHeader = [[RFC2822RawMessageHeader alloc] initWithString: self.sampleHeader];
    
    DDLogVerbose(@"Fields data: \r%@",  self.rfcRawHeader.fields);
}

/*
 root@source.moedae.net (Cron Daemon)
 =?utf-8?Q?customerservice@entertainmentbenefits.com?=
 "=?utf-8?Q?Wyndham=20Vacation=20Resorts?=" <reservationprearrivals@wyndhamvacationresorts.com>
 =?UTF-8?Q?The_general-purpose_Squ?= =?UTF-8?Q?eak_developers_list=C2=A0=C2=A0=C2=A0=C2=A0?= <squeak-dev@lists.squeakfoundation.org>
 =?UTF-8?B?VEFVTiBDSEFQTUFO?= <taun@charcoalia.net>
 */
-(void) testFromAddressQEncodedNoName {
    MBMIME2047ValueTransformer* decoder = [MBMIME2047ValueTransformer new];
    
    NSString* sampleAddress = @"=?utf-8?Q?customerservice@entertainmentbenefits.com?=";
    
    NSString* decodedAddress = [decoder transformedValue: sampleAddress];
    
    SimpleRFC822Address* address = [decodedAddress rfc822Address];
    
    XCTAssertEqualObjects(address.email, @"customerservice@entertainmentbenefits.com", @"bad address");
}
-(void) testFromAddressQEncodedName {
    MBMIME2047ValueTransformer* decoder = [MBMIME2047ValueTransformer new];
    
    NSString* sampleAddress = @"\"=?utf-8?Q?Wyndham=20Vacation=20Resorts?=\" <reservationprearrivals@wyndhamvacationresorts.com>";
    
    NSString* decodedAddress = [decoder transformedValue: sampleAddress];
    
    SimpleRFC822Address* address = [decodedAddress rfc822Address];
    
    XCTAssertEqualObjects(address.email, @"reservationprearrivals@wyndhamvacationresorts.com", @"bad address");
}

@end
