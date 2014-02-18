//
//  MIMERFC2047EncodeDecodeTests.m
//  MailBoxes
//
//  Created by Taun Chapman on 09/16/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "RFC2822RawMessageHeader.h"
#import "MBMIME2047ValueTransformer.h"



@interface MIMERFC2047EncodeDecodeTests : XCTestCase

@property(nonatomic, strong) MBMIME2047ValueTransformer     *mimeEncodingTransformer;
@property(nonatomic, strong) NSBundle                       *testBundle;
@property(nonatomic, strong) NSString                       *sampleHeader;
@property(nonatomic, strong) RFC2822RawMessageHeader        *rfcRawHeader;

@end

@implementation MIMERFC2047EncodeDecodeTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _mimeEncodingTransformer = [MBMIME2047ValueTransformer new];
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
    
    NSString* decoded = [self.mimeEncodingTransformer transformedValue: [self.rfcRawHeader.fields objectForKey: @"SUBJECT"]];
    
    NSString* shouldBe = @"This is just plain text.";

    XCTAssertEqualObjects(decoded, shouldBe, @"Raw header fields: \r%@\rDecoded: %@",  self.rfcRawHeader.fields, decoded);
    //XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}
- (void)testRFC2047SubjectUTFQ {
    NSError *error = nil;
    
    NSString *path = [self.testBundle pathForResource: @"rfc2047SubjectUTF8Q" ofType: @"txt" inDirectory: @"answers"];

    self.sampleHeader = [NSString stringWithContentsOfFile: path encoding: NSASCIIStringEncoding error: &error];
    
    self.rfcRawHeader = [[RFC2822RawMessageHeader alloc] initWithString: self.sampleHeader];

    NSString* decoded = [self.mimeEncodingTransformer transformedValue: [self.rfcRawHeader.fields objectForKey: @"SUBJECT"]];
    
    NSString* shouldBe = @"Your Wyndham Vacation is Almost Here - Resort Details Enclosed!";
    
    XCTAssertEqualObjects(decoded, shouldBe, @"Raw header fields: \r%@\rDecoded: %@",  self.rfcRawHeader.fields, decoded);
    //XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}
//rfc2047ToUTF8Q4l
- (void)testRFC2047ToUTFQMultiline4 {
    NSError *error = nil;
    
    NSString *path = [self.testBundle pathForResource: @"rfc2047ToUTF8Q4l" ofType: @"txt" inDirectory: @"answers"];
    
    self.sampleHeader = [NSString stringWithContentsOfFile: path encoding: NSASCIIStringEncoding error: &error];
    
    self.rfcRawHeader = [[RFC2822RawMessageHeader alloc] initWithString: self.sampleHeader];
    
    NSString* decoded = [self.mimeEncodingTransformer transformedValue: [self.rfcRawHeader.fields objectForKey: @"TO"]];
    
    NSString* shouldBe = @"communications@plone.org,  \"plone-developers@lists. sourceforge. net developers\" <plone-developers@lists.sourceforge.net>,  \"plone-users@lists.sourceforge.net plone-users@lists.sourceforge.net\" <plone-users@lists.sourceforge.net>";
    
    XCTAssertEqualObjects(decoded, shouldBe, @"Raw header fields: \r%@\rDecoded: %@",  self.rfcRawHeader.fields, decoded);
    //XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}
//rfc2047ToUTF8Q3l
- (void)testRFC2047ToUTFQMultiline3 {
    NSError *error = nil;
    
    NSString *path = [self.testBundle pathForResource: @"rfc2047ToUTF8Q3l" ofType: @"txt" inDirectory: @"answers"];
    
    self.sampleHeader = [NSString stringWithContentsOfFile: path encoding: NSASCIIStringEncoding error: &error];
    
    self.rfcRawHeader = [[RFC2822RawMessageHeader alloc] initWithString: self.sampleHeader];
    
    NSString* decoded = [self.mimeEncodingTransformer transformedValue: [self.rfcRawHeader.fields objectForKey: @"TO"]];
    
    NSString* shouldBe = @"The general-purpose Squeak developers list    <squeak-dev@lists.squeakfoundation.org>";
    
    XCTAssertEqualObjects(decoded, shouldBe, @"Raw header fields: \r%@\rDecoded: %@",  self.rfcRawHeader.fields, decoded);
    //XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}
- (void)testRFC2047ToUTFB {
    NSError *error = nil;
    
    //NSString *path = [self.testBundle pathForResource: @"rfc2047SubjectUTF8Q" ofType: @"txt" inDirectory: @"answers"];
    NSString *path = [self.testBundle pathForResource: @"rfc2047ToUTF8B" ofType: @"txt" inDirectory: @"answers"];
    
    self.sampleHeader = [NSString stringWithContentsOfFile: path encoding: NSASCIIStringEncoding error: &error];
    
    self.rfcRawHeader = [[RFC2822RawMessageHeader alloc] initWithString: self.sampleHeader];
    
    NSString* decoded = [self.mimeEncodingTransformer transformedValue: [self.rfcRawHeader.fields objectForKey: @"TO"]];
    
    XCTAssertEqualObjects(decoded, @"TAUN CHAPMAN<taun@charcoalia.net>", @"Raw header fields: \r%@\rDecoded: %@",  self.rfcRawHeader.fields, decoded);
    //XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}
//rfc2047SubjectISO88591B
- (void)testRFC2047SubjectISO88591B {
    NSError *error = nil;
    
    NSString *path = [self.testBundle pathForResource: @"rfc2047SubjectISO88591B" ofType: @"txt" inDirectory: @"answers"];
    
    self.sampleHeader = [NSString stringWithContentsOfFile: path encoding: NSASCIIStringEncoding error: &error];
    
    self.rfcRawHeader = [[RFC2822RawMessageHeader alloc] initWithString: self.sampleHeader];
    
    NSString* decoded = [self.mimeEncodingTransformer transformedValue: [self.rfcRawHeader.fields objectForKey: @"SUBJECT"]];
    
    NSString* shouldBe = @"Survey: Google in the Enterprise - Chance to win a Samsung Smart TV";
    
    XCTAssertEqualObjects(decoded, shouldBe, @"Raw header fields: \r%@\rDecoded: %@",  self.rfcRawHeader.fields, decoded);
    //XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}
// rfc2047ThreadTopicISO88591B2l
- (void)testRFC2047ThreadTopicISO88591B2l {
    NSError *error = nil;
    
    NSString *path = [self.testBundle pathForResource: @"rfc2047ThreadTopicISO88591B2l" ofType: @"txt" inDirectory: @"answers"];
    
    self.sampleHeader = [NSString stringWithContentsOfFile: path encoding: NSASCIIStringEncoding error: &error];
    
    self.rfcRawHeader = [[RFC2822RawMessageHeader alloc] initWithString: self.sampleHeader];
    
    NSString* decoded = [self.mimeEncodingTransformer transformedValue: [self.rfcRawHeader.fields objectForKey: @"THREAD-TOPIC"]];
    
    NSString* shouldBe = @"[squeak-dev] Something in the update process damagesthe    background";
    
    XCTAssertEqualObjects(decoded, shouldBe, @"Raw header fields: \r%@\rDecoded: %@",  self.rfcRawHeader.fields, decoded);
    //XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}
//rfc2047SubjectKOI8RB2l
- (void)testRFC2047SubjectKOI8RB2l {
    NSError *error = nil;
    
    NSString *path = [self.testBundle pathForResource: @"rfc2047SubjectKOI8RB2l" ofType: @"txt" inDirectory: @"answers"];
    
    self.sampleHeader = [NSString stringWithContentsOfFile: path encoding: NSASCIIStringEncoding error: &error];
    
    self.rfcRawHeader = [[RFC2822RawMessageHeader alloc] initWithString: self.sampleHeader];
    
    NSString* decoded = [self.mimeEncodingTransformer transformedValue: [self.rfcRawHeader.fields objectForKey: @"SUBJECT"]];
    
    NSString* shouldBe = @"мАВЩЕ, ДБЦЕ УБНЩЕ ЗТСЪОЩЕ УЕЛУХБМШОЩЕ ЖБОФБЪЙЙ, ПЦЙЧБАФ ЪДЕШ";
    
    XCTAssertEqualObjects(decoded, shouldBe, @"Raw header fields: \r%@\rDecoded: %@",  self.rfcRawHeader.fields, decoded);
    //XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}
- (void)testRFC2047Subject8859Q {
    NSError *error = nil;
    
    NSString *path = [self.testBundle pathForResource: @"rfc2047subject8859Q" ofType: @"txt" inDirectory: @"answers"];
    
    self.sampleHeader = [NSString stringWithContentsOfFile: path encoding: NSASCIIStringEncoding error: &error];
    
    self.rfcRawHeader = [[RFC2822RawMessageHeader alloc] initWithString: self.sampleHeader];
    
    NSString* decoded = [self.mimeEncodingTransformer transformedValue: [self.rfcRawHeader.fields objectForKey: @"SUBJECT"]];
    
    NSString* shouldBe = @"New E-Commerce Articles, Column at StartupJournal.com, The Wall Street Journal?s Center for Entrepreneurs";
    
    XCTAssertEqualObjects(decoded, shouldBe, @"Raw header fields: \r%@\rDecoded: %@",  self.rfcRawHeader.fields, decoded);
    //XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

@end
