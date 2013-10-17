//
//  MBTransformerTests.m
//  MailBoxes
//
//  Created by Taun Chapman on 10/17/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MBMIMECharsetTransformer.h"
#import "MBMIMEQuotedPrintableTranformer.h"
#import "MBMIME2047ValueTransformer.h"

@interface MBTransformerTests : XCTestCase


@property(nonatomic, strong) NSBundle                       *testBundle;

@end

@implementation MBTransformerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _testBundle = [NSBundle bundleWithIdentifier: @"com.moedae.LogicTests"];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}
-(void) saveAnswer: (NSString *) answer As: (NSString *) methodName {
    NSString *fileName = [NSString stringWithFormat: @"%@.archive", methodName];
    NSString *archivePath = [NSHomeDirectory() stringByAppendingPathComponent: fileName];
    [NSKeyedArchiver archiveRootObject: answer toFile: archivePath];
}
-(NSString *) loadAnswersFor: (NSString *) methodName {
    NSString *path = [self.testBundle pathForResource: methodName ofType: @"archive" inDirectory: @"answers"];
    
    NSString *answer = [NSKeyedUnarchiver unarchiveObjectWithFile: path];
    
    return answer;
}

- (void)testFromHTMLQuotedPrintable {
    NSError *error = nil;
    
    NSString *path = [self.testBundle pathForResource: @"mimeTextHTMLQuotedPrintable" ofType: @"txt" inDirectory: @"answers"];
    
    NSString* sampleContent = [NSString stringWithContentsOfFile: path encoding: NSASCIIStringEncoding error: &error];
    
    NSString* decoded = [[MBMIMEQuotedPrintableTranformer new] transformedValue: sampleContent];
    
    if (NO) {
        [self saveAnswer: decoded As: NSStringFromSelector(_cmd)];
    }
    
    NSString *shouldBe = [self loadAnswersFor: NSStringFromSelector(_cmd)];
    
    XCTAssertTrue([decoded isEqualToString: shouldBe], @"Raw content: \r%@\rDecoded: %@", sampleContent, decoded);
    //XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}
-(void)testCharsetUTF8ToNS {
    
}

@end
