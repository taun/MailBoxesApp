//
//  IMAPResponseTests.h
//  MailBoxes
//
//  Created by Taun Chapman on 9/7/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "IMAPResponseParser.h"
#import "IMAPResponseDelegate.h"
#import "IMAPClientStore.h"

@interface IMAPResponseParserTests : XCTestCase <IMAPParsedResponseDelegate, IMAPClientStore> {
    IMAPResponseParser        *parser;
    BOOL                  saveAnswers;
    
    
    NSBundle            *testBundle;
}

@property (strong) IMAPResponseParser *parser;
@property (copy)     NSString         *actionCalled;


@end
