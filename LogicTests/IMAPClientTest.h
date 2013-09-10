//
//  IMAPClientTest.h
//  MailBoxes
//
//  Created by Taun Chapman on 9/5/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Cocoa/Cocoa.h>
#import "IMAPResponseDelegate.h"
#import "IMAPClientStore.h"

//@class IMAPClient;
@class IMAPResponseBuffer;
@class IMAPCoreDataStore;
@class MBox;

@interface IMAPClientTest : XCTestCase <IMAPResponseDelegate> {
    
    NSPersistentStoreCoordinator *coord;
    NSManagedObjectContext *ctx;
    NSManagedObjectModel *model;
    NSPersistentStore *store;

    //IMAPClient *imapClient;
    IMAPResponseBuffer        *parser;
    BOOL                  saveAnswers;
    
    
    NSBundle            *testBundle;
    IMAPCoreDataStore*    clientStore;
    
    MBox*               selectedBox;
}

@property (retain) IMAPResponseBuffer *parser;
@property (copy)     NSString         *actionCalled;

@end
