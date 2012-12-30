//
//  RFC2822RawMessageHeaderTest.h
//  MailBoxes
//
//  Created by Taun Chapman on 10/5/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
@class RFC2822RawMessageHeader;

@interface RFC2822RawMessageHeaderTest : SenTestCase

@property(nonatomic, retain) NSBundle                   *testBundle;
@property(nonatomic, retain) NSString                   *sampleHeader;
@property(nonatomic, retain) RFC2822RawMessageHeader    *rfcRawHeader;

@end
