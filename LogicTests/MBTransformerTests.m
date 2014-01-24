//
//  MBTransformerTests.m
//  MailBoxes
//
//  Created by Taun Chapman on 10/17/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "SimpleRFC822Address.h"

#import "MBMIMECharsetTransformer.h"
#import "MBMIMEQuotedPrintableTranformer.h"
#import "MBMIME2047ValueTransformer.h"
#import "MBSimpleRFC822AddressToStringTransformer.h"
#import "MBSimpleRFC822AddressSetToStringTransformer.h"

#pragma message "ToDo: need stub MBAddress class for testing transformer."

@interface MBTransformerTests : XCTestCase


@property(nonatomic, strong) NSBundle                       *testBundle;

@end

@implementation MBTransformerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _testBundle = [NSBundle bundleWithIdentifier: @"com.moedae.LogicTests"];

    [NSValueTransformer setValueTransformer: [MBSimpleRFC822AddressToStringTransformer new]
                                    forName: VTAddressToString];
    
    [NSValueTransformer setValueTransformer: [MBSimpleRFC822AddressSetToStringTransformer new]
                                    forName: VTAddressesToString];
    
    [NSValueTransformer setValueTransformer: [MBMIME2047ValueTransformer new]
                                    forName: VTRFC2047EncodedToString];
    
    [NSValueTransformer setValueTransformer: [MBMIMEQuotedPrintableTranformer new]
                                    forName: VTQuotedPrintableToString];
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

-(NSString*) tranformAddress: (id) address {
    NSValueTransformer* addressToStringTransformer = [NSValueTransformer valueTransformerForName: VTAddressToString];
    NSString* addressString = [addressToStringTransformer transformedValue: address];
    return addressString;
}
-(SimpleRFC822Address*) reverseTranformAddress: (NSString*) string {
    NSValueTransformer* addressToStringTransformer = [NSValueTransformer valueTransformerForName: VTAddressToString];
    SimpleRFC822Address* address = [addressToStringTransformer reverseTransformedValue: string];
    return address;
}

-(NSSet*) reverseTranformAddresses: (NSString*) string {
    NSValueTransformer* addressesToStringTransformer = [NSValueTransformer valueTransformerForName: VTAddressesToString];
    NSSet* addresses = [addressesToStringTransformer reverseTransformedValue: string];
    return addresses;
}

-(NSString*) transformAddressesToString: (NSSet*) addresses {
    NSValueTransformer* addressesToStringTransformer = [NSValueTransformer valueTransformerForName: VTAddressesToString];
    NSString* string = [addressesToStringTransformer transformedValue: addresses];
    return string;
}

-(void)testStringToAddress1 {
    SimpleRFC822Address* address = [self reverseTranformAddress: @"Taun Chapman <taun@taun.org>"];
    SimpleRFC822Address* reference = [SimpleRFC822Address newAddressName: @"Taun Chapman" email: @"taun@taun.org"];
    XCTAssertEqualObjects(address, reference, @"%@ & %@ should be the same.", address, reference);
}

-(void)testMultipleAddressesStringToSet {
    NSString* addresses = [NSString stringWithFormat: @"Taun Chapman <taun@taun.org>, Taun Chapman <news@taun.org>, myrna@charcoalia.net"];
    NSSet* simpleAddressSet = [self reverseTranformAddresses: addresses];
    NSString* reference = [self transformAddressesToString: simpleAddressSet];
    
    XCTAssertEqualObjects(addresses, reference, @"%@ & %@ Should be equal.", addresses, reference);
}
@end
