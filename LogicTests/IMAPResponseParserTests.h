//
//  IMAPResponseTests.h
//  MailBoxes
//
//  Created by Taun Chapman on 9/7/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import "IMAPResponseBuffer.h"
#import "IMAPResponseDelegate.h"
#import "IMAPClientStore.h"

@interface IMAPResponseParserTests : SenTestCase <IMAPResponseDelegate, IMAPClientStore> {
    IMAPResponseBuffer        *parser;
    BOOL                  saveAnswers;
    
    
    NSBundle            *testBundle;
}

@property (retain) IMAPResponseBuffer *parser;
@property (copy)     NSString         *actionCalled;


@end
