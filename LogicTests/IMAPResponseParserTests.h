//
//  IMAPResponseTests.h
//  MailBoxes
//
//  Created by Taun Chapman on 9/7/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "IMAPResponseBuffer.h"
#import "IMAPResponseDelegate.h"
#import "IMAPClientStore.h"

@interface IMAPResponseParserTests : XCTestCase <IMAPResponseDelegate, IMAPClientStore> {
    IMAPResponseBuffer        *parser;
    BOOL                  saveAnswers;
    
    
    NSBundle            *testBundle;
}

@property (strong) IMAPResponseBuffer *parser;
@property (copy)     NSString         *actionCalled;


@end
