//
//  MBIMAPMemCacheStoreTests.m
//  MailBoxes
//
//  Created by Taun Chapman on 04/28/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MBMessage+IMAP.h"
#import "MBox+IMAP.h"
#import "MBAccount+IMAP.h"


@interface MBIMAPMemCacheStoreTests : XCTestCase

@end

@implementation MBIMAPMemCacheStoreTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

-(void)testMboxCreation {
    MBAccount* account = [MBAccount new];
    account.name = @"Charcoalia";
    
    MBox* box = [MBox new];
    box.name = @"Test";
    box.accountReference = account;
}
@end
