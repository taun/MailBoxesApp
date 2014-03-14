//
//  MBTransformerTests.m
//  MailBoxes
//
//  Created by Taun Chapman on 10/17/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <MoedaeMailPlugins/SimpleRFC822Address.h>

#import "MBMIMECharsetTransformer.h"
#import "MBMIMEQuotedPrintableTranformer.h"
#import "MBMIME2047ValueTransformer.h"
#import "MBSimpleRFC822AddressToStringTransformer.h"
#import "MBSimpleRFC822AddressSetToStringTransformer.h"
#import "MBEncodedStringHexOctetTransformer.h"

#import "MBEncodedString.h"

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
                                    forName: VTMBSimpleRFC822AddressToStringTransformer];
    
    [NSValueTransformer setValueTransformer: [MBSimpleRFC822AddressSetToStringTransformer new]
                                    forName: VTMBSimpleRFC822AddressSetToStringTransformer];
    
    [NSValueTransformer setValueTransformer: [MBMIME2047ValueTransformer new]
                                    forName: VTMBMIME2047ValueTransformer];
    
    [NSValueTransformer setValueTransformer: [MBMIMEQuotedPrintableTranformer new]
                                    forName: VTMBMIMEQuotedPrintableTranformer];

    [NSValueTransformer setValueTransformer: [MBEncodedStringHexOctetTransformer new]
                                    forName: VTMBEncodedStringHexOctetTransformer];
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

- (void)testFromquotedPrintableISO88591 {
    NSError *error = nil;
    
    NSString *path = [self.testBundle pathForResource: @"quotedPrintableISO-8859-1" ofType: @"txt" inDirectory: @"answers"];
    
    NSString* sampleContent = [NSString stringWithContentsOfFile: path encoding: NSASCIIStringEncoding error: &error];
    
    MBEncodedString* encodedString = [MBEncodedString newEncodedString: sampleContent encoding: NSISOLatin1StringEncoding];
    
    MBEncodedString* dehexedString = [[MBMIMEQuotedPrintableTranformer new] transformedValue: encodedString];
    
    NSData* decoded = [dehexedString asData]; // 5 = iso-8859-1

    NSString* unicodeDecoded = [[NSString alloc] initWithData: decoded encoding: 5];
    
//    if (NO) {
//        [self saveAnswer: decoded As: NSStringFromSelector(_cmd)];
//    }
//    
//    NSString *shouldBe = [self loadAnswersFor: NSStringFromSelector(_cmd)];
//    
//    XCTAssertTrue([decoded isEqualToString: shouldBe], @"Raw content: \r%@\rDecoded: %@", sampleContent, decoded);
    //XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

-(void)testCharsetUTF8ToNS {
    
}

#pragma mark - Address Transform tests

-(NSString*) tranformAddress: (id) address {
    NSValueTransformer* addressToStringTransformer = [NSValueTransformer valueTransformerForName: VTMBSimpleRFC822AddressToStringTransformer];
    NSString* addressString = [addressToStringTransformer transformedValue: address];
    return addressString;
}
-(SimpleRFC822Address*) reverseTranformAddress: (NSString*) string {
    NSValueTransformer* addressToStringTransformer = [NSValueTransformer valueTransformerForName: VTMBSimpleRFC822AddressToStringTransformer];
    SimpleRFC822Address* address = [addressToStringTransformer reverseTransformedValue: string];
    return address;
}

-(NSSet*) reverseTranformAddresses: (NSString*) string {
    NSValueTransformer* addressesToStringTransformer = [NSValueTransformer valueTransformerForName: VTMBSimpleRFC822AddressSetToStringTransformer];
    NSSet* addresses = [addressesToStringTransformer reverseTransformedValue: string];
    return addresses;
}

-(NSString*) transformAddressesToString: (NSSet*) addresses {
    NSValueTransformer* addressesToStringTransformer = [NSValueTransformer valueTransformerForName: VTMBSimpleRFC822AddressSetToStringTransformer];
    NSString* string = [addressesToStringTransformer transformedValue: addresses];
    return string;
}

-(void)testEmptyStringToAddress1 { // should return nil
    SimpleRFC822Address* address = [self reverseTranformAddress: @" "];
    XCTAssertNil(address, @"%@ should be nil.", address);
}

-(void)testStringToAddress1 {
    SimpleRFC822Address* address = [self reverseTranformAddress: @"Taun Chapman <taun@taun.org>"];
    SimpleRFC822Address* reference = [SimpleRFC822Address newAddressName: @"Taun Chapman" email: @"taun@taun.org"];
    XCTAssertEqualObjects(address, reference, @"%@ & %@ should be the same.", address, reference);
}

-(void)testEmptyAddressesStringToSet { // should return empty set
    NSString* addresses = [NSString stringWithFormat: @" "];
    NSSet* simpleAddressSet = [self reverseTranformAddresses: addresses];
    
    XCTAssertTrue((simpleAddressSet.count == 0), @"%@ Should be empty.", addresses);
}

-(void)testMultipleAddressesStringToSet {
    NSString* addresses = [NSString stringWithFormat: @"\"'Taun'\" <taun@taun.org>, \"Taun Chapman\" <taun@taun.org>, \"Taun Chapman\" <news@taun.org>, <myrna@charcoalia.net>"];
    NSSet* simpleAddressSet = [self reverseTranformAddresses: addresses];
    NSString* reference = [self transformAddressesToString: simpleAddressSet];
    
    XCTAssertEqualObjects(addresses, reference, @"%@ & %@ Should be equal.", addresses, reference);
}

-(void)testLongAddressesStringNamesWithCommasToSet {
    NSString* addresses = [NSString stringWithFormat: @"\"Mike Lee\" <mlee@rdpartners.com>, <wilkins@umbi.umd.edu>, \"Clayton Cardin\" <clayton.cardin@verizon.net>, \"PaGeN\" <pagen@io.com>, \"David Wieger\" <davidmichaelw@hotmail.com>, \"Gary Seldon\" <garyseldon@earthlink.net>, \"Jeff Malmgren\" <coord@vul.bc.ca>, \"Mark Walker\" <mwalker@skyytek.com>, \"Nick Roberts\" <nroberts@cyberus.ca>, \"peter roper\" <roper@portofolio.com>, \"Pieter Botman\" <P.BOTMAN@IEEE.ORG>, <Puttyhead@aol.com>, \"rob seidenberg\" <robseidenberg@yahoo.com>, <apeters@bhsusa.com>, \"Jamie Demarest\" <Jamie_demarest@newton.mec.edu>, \"Charles Shoemaker\" <charles.shoemaker@tufts.edu>, \"Scott Todd\" <sasha@scottsasha.com>, \"Michael Fortman\" <mcfortman@yahoo.com>, \"Matt J and Lori B\" <maplerowfarm@yahoo.com>, \"terry plotkin\" <tplotkin@earthlink.net>, \"Bowen, Mike\" <mike.bowen@bmonb.com>, \"Mark Corsey\" <eclipsemc@earthlink.net>, \"rob botman\" <rob.botman@gmail.com>, \"Moran, Mark D\" <mdmoran@kpmg.ca>, \"Jeffrey Wood\" <jeff@agencynextdoor.com>, \"Glenn Ulmer\" <GUlmer@syscom-consulting.com>, \"Tim Friesen\" <tim.friesen@telusplanet.net>, \"David Finn\" <finner64@gmail.com>, <stephen.wiencke@bmo.com>, \"Bruton, Peter\" <bruton@NRCan.gc.ca>, \"Fielding, Craig\" <Craig.Fielding@cra-arc.gc.ca>, \"J. Invencio\" <bosgmasters@mac.com>, <canniff@canniff.net>, \"Dave Wilkins\" <wilkins@umbi.umd.edu>, \"B KIRBY\" <ber01906@berk.com>, \"Taun\" <taun@charcoalia.net>"];
    NSSet* simpleAddressSet = [self reverseTranformAddresses: addresses];
    NSString* reference = [self transformAddressesToString: simpleAddressSet];
    NSSet* simpleAddressSet2 = [self reverseTranformAddresses: reference];
    BOOL success = [simpleAddressSet2 isEqualToSet: simpleAddressSet];
    XCTAssertTrue(success, @"%@ & %@ Should be equal.", addresses, reference);
}

/*
 "'Trisha Tuttle'" <tbtut@aol.com>,	<dbasarab13@gmail.com>, <chamberlain51@comcast.net>,	<hjm041370@gmail.com>,	<adembrak@yahoo.com>, <wendy.dembrak@gmail.com>,	<jamesmckay@verizon.net>, <patrick.a.olivares@gmail.com>,	<jsarr@phoenixmanagement.com>, <marta@gigamyte.com>,	<todd@intelligentprofit.com>,	<mike_stagnaro@yahoo.com>, <theowells@gmail.com>,	<lescraig@hotmail.com>,	<barbycraig@hotmail.com>, <btuttle@teksystems.com>,	<the5mcqs@gmail.com>,	<ajbaci4@yahoo.com>, <arjetbaci@yahoo.com>,	<taun@charcoalia.net>,	<mmckay00@juno.com>, <myrna@charcoalia.net>
 */
-(void)testLongAddressesStringNamesWithCommasAndTabsToSet {
    NSString* addresses = [NSString stringWithFormat: @"\"'Trisha Tuttle'\" <tbtut@aol.com>,	<dbasarab13@gmail.com>, <chamberlain51@comcast.net>,	<hjm041370@gmail.com>,	<adembrak@yahoo.com>, <wendy.dembrak@gmail.com>,	<jamesmckay@verizon.net>, <patrick.a.olivares@gmail.com>,	<jsarr@phoenixmanagement.com>, <marta@gigamyte.com>,	<todd@intelligentprofit.com>,	<mike_stagnaro@yahoo.com>, <theowells@gmail.com>,	<lescraig@hotmail.com>,	<barbycraig@hotmail.com>, <btuttle@teksystems.com>,	<the5mcqs@gmail.com>,	<ajbaci4@yahoo.com>, <arjetbaci@yahoo.com>,	<taun@charcoalia.net>,	<mmckay00@juno.com>, <myrna@charcoalia.net>"];
    NSSet* simpleAddressSet = [self reverseTranformAddresses: addresses];
    NSString* reference = [self transformAddressesToString: simpleAddressSet];
    NSSet* simpleAddressSet2 = [self reverseTranformAddresses: reference];
    BOOL success = [simpleAddressSet2 isEqualToSet: simpleAddressSet];
    XCTAssertTrue(success, @"%@ & %@ Should be equal.", addresses, reference);
}


-(void)testLongAddressesStringNamesWithQEncodeToSet {
    NSString* addresses = [NSString stringWithFormat: @"\"'Mike Kropveld'\" <grandmasters@operamail.com>,                        \"'Laurie Dotto'\" <laurie.dotto@abbott.com>,                       \"'Lorne Beckman'\" <lorne@orl.mcgill.ca>,                         \"'Shiellah Quintos'\" <shiellah@sympatico.ca>,                       =?iso-8859-1?Q?'Lariv=E9e=2C_Jean-Fran=E7ois'?= <Larivee-J-F@positron911.com>"];
    NSSet* simpleAddressSet = [self reverseTranformAddresses: addresses];
    NSString* reference = [self transformAddressesToString: simpleAddressSet];
    NSSet* simpleAddressSet2 = [self reverseTranformAddresses: reference];
    BOOL success = [simpleAddressSet2 isEqualToSet: simpleAddressSet];
    XCTAssertTrue(success, @"%@ & %@ Should be equal.", addresses, reference);
}

-(void)testAddressesStringNamesWithCommasAndNoBracketToSet {
    NSString* addresses = [NSString stringWithFormat: @"MANDT@CHARCOALIA.NET, \n\tMYRNA.A.MONCK@GSK.COM"];
    NSSet* simpleAddressSet = [self reverseTranformAddresses: addresses];
    NSString* reference = [self transformAddressesToString: simpleAddressSet];
    NSSet* simpleAddressSet2 = [self reverseTranformAddresses: reference];
    BOOL success = [simpleAddressSet2 isEqualToSet: simpleAddressSet];
    XCTAssertTrue(success, @"%@ & %@ Should be equal.", addresses, reference);
}


@end
