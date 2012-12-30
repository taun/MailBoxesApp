//
//  IMAPClientTest.m
//  MailBoxes
//
//  Created by Taun Chapman on 9/5/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import "IMAPClientTest.h"
//#import "../Classes/IMAPClient.h"
#import "MBAccount.h"
#import "MBAccount+IMAP.h"
#import "MBox.h"
#import "MBox+IMAP.h"
#import "MBMessage.h"
#import "MBMessage+IMAP.h"
#import "IMAPResponseBuffer.h"
#import "IMAPResponse.h"
#import "MBTokenTree.h"
#import "IMAPCommand.h"
#import "IMAPCoreDataStore.h"

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation IMAPClientTest

@synthesize parser;
@synthesize actionCalled;


- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    NSArray *bundles = [NSArray arrayWithObject:[NSBundle bundleForClass:[self class]]];
    
    model = [[NSManagedObjectModel mergedModelFromBundles:bundles] retain];
    
    coord = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: model];
    store = [coord addPersistentStoreWithType: NSInMemoryStoreType
                                configuration: nil
                                          URL: nil
                                      options: nil
                                        error: NULL];
    ctx = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSMainQueueConcurrencyType];
    [ctx setPersistentStoreCoordinator: coord];

    //MBUser *newUser;
    //newUser = [NSEntityDescription insertNewObjectForEntityForName:@"MBUser" inManagedObjectContext: ctx];
    //[newUser setValue: @"default" forKey: @"firstName"];
    
    MBAccount *newAccount;
    newAccount = [NSEntityDescription insertNewObjectForEntityForName:@"MBAccount" inManagedObjectContext: ctx];
    [newAccount setValue: @"defaultAccount" forKey: @"name"];
    
    MBox *newMBox;
    newMBox = [NSEntityDescription insertNewObjectForEntityForName:@"MBox" inManagedObjectContext: ctx];
    [newMBox setValue: @"inbox" forKey: @"fullPath"];
    [newMBox setValue: @"inbox" forKey: @"name"];
    [newMBox setValue: @"10" forKey: @"uid"];

    selectedBox = newMBox;
    
    [newAccount addChildNodesObject: newMBox];
    [newAccount addAllNodesObject: newMBox];



    clientStore = [[IMAPCoreDataStore alloc] initWithParentContext: ctx AccountID: [newAccount objectID]];

    parser = [[IMAPResponseBuffer alloc] init];
    [parser setDelegate: self];
    
    testBundle = [NSBundle bundleWithIdentifier: @"com.moedae.LogicTests"];

    //[newUser addChildNodesObject: newAccount];

    //imapClient = [[IMAPClient alloc] initWithAccount: [newAccount objectID]];
    
}

- (void)tearDown
{
    // Tear-down code here.
    //[imapClient release];
    
    [ctx release];
    ctx = nil;
    NSError *error = nil;
    STAssertTrue([coord removePersistentStore: store error: &error],
                 @"couldn't remove persistent store: %@", error);
    store = nil;
    [coord release];
    coord = nil;
    [model release];
    model = nil;

    [super tearDown];
}

- (void)testThatEnvironmentWorks
{
    STAssertNotNil(store, @"no persistent store");
}

/*! 
 ToDo: need to create a ClientStore
 */
- (void)configDefaultResponse:(IMAPResponse *)response {
    response.delegate = self;
    response.clientStore = clientStore;
    IMAPCommand* command = [[IMAPCommand alloc] initWithAtom: @""];
    command.mboxFullPath = @"/test";
    response.command = command;
}

-(void) saveAnswer: (NSData *) mime As: (NSString *) name {
    NSString *fileName = [NSString stringWithFormat: @"%@.xml", name];
    NSString *archivePath = [NSHomeDirectory() stringByAppendingPathComponent: fileName];
//    [NSKeyedArchiver archiveRootObject: mime toFile: archivePath];
    
    [mime writeToFile: archivePath atomically: NO];
    
}

-(NSData*) getSavedAnswer: (NSString*) name {
    NSString *path = [testBundle pathForResource: name ofType: @"xml" inDirectory: @"answers"];
    
    NSData* answer = [[NSData alloc] initWithContentsOfFile: path];
    
    return answer;
}
  
-(BOOL) compareData: (NSData*) data1 with: (NSData*) data2 {
    BOOL result = YES;
    NSString* string1 = [[NSString alloc] initWithData: data1 encoding: NSASCIIStringEncoding];
    NSString* string2 = [[NSString alloc] initWithData: data2 encoding: NSASCIIStringEncoding];
    
    result = [string1 isEqualToString: string2];
    return result;
}

- (void) parseFile: (NSString*) fileName saveAnswer: (BOOL) saving {
    NSString *path = [testBundle pathForResource: fileName ofType: @"txt" inDirectory: @"answers"];
    
    NSMutableData *newData = [NSMutableData dataWithContentsOfMappedFile: path];
    
    [clientStore selectMailBox: @"inbox"];
    
    [parser addDataBuffer: newData];
    [newData release];
    
    IMAPResponse* response = nil;
    IMAPParseResult result = [self.parser parseBuffer: &response];
    
    //    NSMutableArray *tokens = [response.tokens tokenArray];
    
    //    if (saveAnswers) {
    //        [self saveAnswer: tokens As: NSStringFromSelector(_cmd)];
    //    }
    
    //    NSMutableArray *answerTokens = [self loadAnswersFor: NSStringFromSelector(_cmd)];
    //    
    //    STAssertEqualObjects(tokens, answerTokens, @"Parse result: %i", result);
    //    STAssertTrue(result == IMAPParseComplete, @"Parse result: %i", result);
    
    [self configDefaultResponse:response];
    if (result) {
        [response evaluate];
        [clientStore save: nil];
        
        NSData* correctData;
        
        NSMutableData* archiveData = [[NSMutableData alloc] init];
        NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: archiveData];
        [archiver setOutputFormat: NSPropertyListXMLFormat_v1_0];
        [archiver encodeObject: [[[selectedBox.messages anyObject] childNodes] objectAtIndex: 0] forKey: @"root"];
        [archiver finishEncoding];
        if (YES) {
            [self saveAnswer: archiveData As: fileName];
        }
        
        correctData = [self getSavedAnswer: fileName];
        
        BOOL isDataCorrect = [self compareData: correctData with: archiveData];
        NSString* isCorrectString = isDataCorrect ? @"YES" : @"NO";
        NSLog(@"New data and correct answer are same? %@",isCorrectString);
        STAssertTrue(isDataCorrect, @"Data is not corect. %@", isCorrectString);
    }
    
    NSLog(@"SelectedBox: %@", selectedBox);
    
    //    NSString *responseMethodName = @"setMessage:";
    //    STAssertTrue([responseMethodName compare: self.actionCalled] == NSOrderedSame, @"Response method called should be: %@, was:", responseMethodName, self.actionCalled);
    // need to assert result of above
    // set an ivar in delegate method with name and arguments passed to delegate method
    // compare to desired.
    
}

- (void)testRespFetchUidBodystructureMultiPartImageMessage {
    
    [self parseFile:@"fetchBodystructureMultipartMessageImageA" saveAnswer: YES];
}

- (void)testRespFetchUidBodystructureMultiPartSigned {
    
    [self parseFile:@"fetchBodystructurePGPSigned" saveAnswer: YES];
}

- (void)testRespFetchUidBodystructureMultiPartApplicationExcel {
    
    [self parseFile:@"fetchBodystructureApplicationExcel" saveAnswer: YES];
}

- (void)testRespFetchUidBodystructureTextHtml {
    
    [self parseFile:@"fetchBodystructureTextHtmlEncoded" saveAnswer: YES];
}

//TODO need a bodystructure before we can test the body part
// parts are just data to attach to a pre-existing structure
- (void)testRespFetchBodyPart2 {
    
    [self parseFile:@"fetchBodyPart2" saveAnswer: YES];
}

-(void) responseFetch: (id) response {
    //IMAPResponseBuffer *passedParser = (IMAPResponseBuffer *)response;
    //MBTokenTree *tokens = passedParser.tokens;
    //DDLogVerbose(@"delegate method: %@ - parser tokens: %@", NSStringFromSelector(_cmd), tokens);
    self.actionCalled = NSStringFromSelector(_cmd);
}


@end
