//
//  MIMERFC2047EncodeDecodeTests.m
//  MailBoxes
//
//  Created by Taun Chapman on 09/16/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "RFC2822RawMessageHeader.h"
#import "MBMIME2047Formatter.h"



@interface MIMERFC2047EncodeDecodeTests : XCTestCase

@property(nonatomic, strong) MBMIME2047Formatter        *mimeFormatter;
@property(nonatomic, strong) NSBundle                   *testBundle;
@property(nonatomic, strong) NSString                   *sampleHeader;
@property(nonatomic, strong) RFC2822RawMessageHeader    *rfcRawHeader;

@end

@implementation MIMERFC2047EncodeDecodeTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _mimeFormatter = [MBMIME2047Formatter new];
    _testBundle = [NSBundle bundleWithIdentifier: @"com.moedae.LogicTests"];
    _sampleHeader = nil;
    _rfcRawHeader = nil;
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testRFC2047SubjectASCII {
    
    self.sampleHeader = @"Subject: This is just plain text.";
    
    self.rfcRawHeader = [[RFC2822RawMessageHeader alloc] initWithString: self.sampleHeader];
    
    NSString* decoded = [self.mimeFormatter stringForObjectValue: [self.rfcRawHeader.fields objectForKey: @"SUBJECT"]];
    
    XCTAssertEqualObjects(decoded, @"string", @"Raw header fields: \r%@\rDecoded: %@",  self.rfcRawHeader.fields, decoded);
    //XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}
- (void)testRFC2047SubjectUTFQ {
    NSError *error = nil;
    
    NSString *path = [self.testBundle pathForResource: @"rfc2047SubjectUTF8Q" ofType: @"txt" inDirectory: @"answers"];

    self.sampleHeader = [NSString stringWithContentsOfFile: path encoding: NSASCIIStringEncoding error: &error];
    
    self.rfcRawHeader = [[RFC2822RawMessageHeader alloc] initWithString: self.sampleHeader];

    NSString* decoded = [self.mimeFormatter stringForObjectValue: [self.rfcRawHeader.fields objectForKey: @"SUBJECT"]];
    
    XCTAssertEqualObjects(decoded, @"string", @"Raw header fields: \r%@\rDecoded: %@",  self.rfcRawHeader.fields, decoded);
    //XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}
- (void)testRFC2047ToUTFB {
    NSError *error = nil;
    
    //NSString *path = [self.testBundle pathForResource: @"rfc2047SubjectUTF8Q" ofType: @"txt" inDirectory: @"answers"];
    NSString *path = [self.testBundle pathForResource: @"rfc2047ToUTF8B" ofType: @"txt" inDirectory: @"answers"];
    
    self.sampleHeader = [NSString stringWithContentsOfFile: path encoding: NSASCIIStringEncoding error: &error];
    
    self.rfcRawHeader = [[RFC2822RawMessageHeader alloc] initWithString: self.sampleHeader];
    
    NSString* decoded = [self.mimeFormatter stringForObjectValue: [self.rfcRawHeader.fields objectForKey: @"TO"]];
    
    XCTAssertEqualObjects(decoded, @"string", @"Raw header fields: \r%@\rDecoded: %@",  self.rfcRawHeader.fields, decoded);
    //XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

@end
