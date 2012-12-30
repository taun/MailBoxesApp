//
//  RFC2822RawMessageHeaderTest.m
//  MailBoxes
//
//  Created by Taun Chapman on 10/5/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import "RFC2822RawMessageHeaderTest.h"
#import "RFC2822RawMessageHeader.h"

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
@end
