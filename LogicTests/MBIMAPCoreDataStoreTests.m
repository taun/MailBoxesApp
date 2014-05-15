//
//  MBIMAPCoreDataStoreTests.m
//  MailBoxes
//
//  Created by Taun Chapman on 05/07/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "IMAPCoreDataStore.h"
#import "IMAPClient.h"

#import "MBTreeNode+IntersectsSetFix.h"

#import "MBAccount+IMAP.h"
#import "MBox+IMAP.h"
#import "MBMessage+IMAP.h"
#import "MBMimeMessage+IMAP.h"
#import "MBMimeImage+IMAP.h"

#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

static NSString* kDefaultBoxPath = @"inbox";

@interface MBIMAPCoreDataStoreTests : XCTestCase <IMAPResponseParserDelegate,IMAPParsedResponseDelegate>

@property(nonatomic,strong) NSBundle                        *testBundle;

@property(nonatomic,strong) NSPersistentStoreCoordinator    *coordinator;
@property(nonatomic,strong) NSManagedObjectContext          *context;
@property(nonatomic,strong) NSManagedObjectModel            *model;
@property(nonatomic,strong) NSPersistentStore               *store;

@property(nonatomic,strong) IMAPClient                      *imapClient;
@property(nonatomic,strong) IMAPResponseParser              *parser;
@property(nonatomic,assign) BOOL                            saveAnswers;

@property(nonatomic,strong) IMAPCoreDataStore               *clientStore;
@property(nonatomic,strong) MBox                            *selectedBox;

/*!
 Whether the parse should be complete, waiting, unexpected end, ...
 */
@property (nonatomic,assign) IMAPParseResult                expectedParseResult;
@property (nonatomic,strong) NSString                       *answer;

@property (nonatomic,strong) NSString                       *postEvalCheckMethod;

@end

@implementation MBIMAPCoreDataStoreTests

- (void)setUp
{
    [super setUp];
// Put setup code here. This method is called before the invocation of each test method in the class.
    NSArray *bundles = [NSArray arrayWithObject:[NSBundle bundleForClass:[self class]]];

    self.model = [NSManagedObjectModel mergedModelFromBundles: bundles];

    self.coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: self.model];

    self.store = [self.coordinator addPersistentStoreWithType: NSInMemoryStoreType
                                configuration: nil
                                          URL: nil
                                      options: nil
                                        error: NULL];

    self.context = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSMainQueueConcurrencyType];
    [self.context setPersistentStoreCoordinator: self.coordinator];

    //MBUser *newUser;
    //newUser = [NSEntityDescription insertNewObjectForEntityForName:@"MBUser" inManagedObjectContext: ctx];
    //[newUser setValue: @"default" forKey: @"firstName"];

    MBAccount *newAccount;
    newAccount = [NSEntityDescription insertNewObjectForEntityForName:@"MBAccount" inManagedObjectContext: self.context];
    [newAccount setValue: @"defaultAccount" forKey: @"name"];

    MBox *newMBox;
    newMBox = [NSEntityDescription insertNewObjectForEntityForName:@"MBox" inManagedObjectContext: self.context];
    [newMBox setValue: kDefaultBoxPath forKey: @"fullPath"];
    [newMBox setValue: kDefaultBoxPath forKey: @"name"];
    [newMBox setValue: @10 forKey: @"uid"];
    // selected mail box searches all mailboxes for accountReference matching account and fullPath matching path.
    [newMBox setValue: newAccount forKey: @"accountReference"];

    [newAccount setValue: [NSOrderedSet orderedSetWithObjects: newMBox, nil] forKey: @"childNodes"];

    self.selectedBox = newMBox;


//    MBTreeNode* parentNode = (MBTreeNode*)newAccount;
//    [parentNode insertObject: selectedBox inChildNodesAtIndex: 0];
//    [selectedBox addParentNodesObject: parentNode];

//    [parentNode addChildNodesObject: selectedBox];
//    [parentNode setIsLeaf: @YES];



    self.clientStore = [[IMAPCoreDataStore alloc] initWithParentContext: self.context AccountID: [newAccount objectID]];
    self.clientStore.selectedMBox = self.selectedBox;

    self.parser = [IMAPResponseParser newResponseBufferWithDefaultStore: self.clientStore];
    [self.parser setBufferDelegate: self];

    self.testBundle = [NSBundle bundleWithIdentifier: @"com.moedae.LogicTests"];

    self.saveAnswers = NO;
    
    //[newUser addChildNodesObject: newAccount];

    //imapClient = [[IMAPClient alloc] initWithAccount: [newAccount objectID]];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];

    self.selectedBox = nil;
    self.context = nil;
    NSError *error = nil;
    XCTAssertTrue([self.coordinator removePersistentStore: self.store error: &error],
                 @"couldn't remove persistent store: %@", error);
    self.store = nil;
    self.coordinator = nil;
    self.model = nil;
}

#pragma mark - utility methods
/*!
 Save the correct answer as a plist on the file system.
 
 @param tokens     the parsed tokens to be converted.
 @param methodName the test method name to be used as the file name.
 */
-(void) saveAnswer: (NSMutableArray *) tokens As: (NSString *) methodName {
    NSString *fileName = [NSString stringWithFormat: @"%@.archive", methodName];
    NSString *archivePath = [NSHomeDirectory() stringByAppendingPathComponent: fileName];
    [NSKeyedArchiver archiveRootObject: tokens toFile: archivePath];
}
/*!
 Load the save answer plist and convert to an array of tokens.
 
 @param methodName the name of the test method used when saving the answers.
 
 @return an NSArray or parsed tokens.
 */
-(NSMutableArray *) loadAnswersFor: (NSString *) methodName {
    NSString *path = [self.testBundle pathForResource: methodName ofType: @"archive" inDirectory: @"answers"];
    
    NSMutableArray *answerTokens = [NSKeyedUnarchiver unarchiveObjectWithFile: path];
    
    return answerTokens;
}
-(void) checkAnswersFor: (IMAPParsedResponse*) parsedResponse {
    
    BOOL parseMatch = self.expectedParseResult == self.parser.result;
    NSString* resultString = [IMAPResponseParser resultAsString: self.parser.result];
    NSString* expectedString = [IMAPResponseParser resultAsString: self.expectedParseResult];
    XCTAssertTrue(parseMatch, @"Expected result: %@; Actual result: %@;", expectedString, resultString);
    
    NSMutableArray *tokens = [parsedResponse.tokens tokenArray];
    NSMutableArray *answerTokens = [self loadAnswersFor: self.answer];
    BOOL success = [tokens isEqualToArray: answerTokens];
    XCTAssertTrue(success, @"Parse tokens should be: \n%@; are: \n%@;", answerTokens, tokens);
}
/*!
 Root utility method for starting the parsing.
 
 @param sampleResponseData IMAPResponse formatted data.
 @param answer             filename of answer file if the response is to be saved as a "correct" response for future tests.
 */
- (void) parseDataBuffer: (NSMutableData*) sampleResponseData {
    [self.parser startParsing];
    [self.parser addDataBuffer: sampleResponseData];
    
    // the parsing is on a separate queue and needs a chance to run and dispatch delegate methods.
    NSDate* loopInterval = [NSDate dateWithTimeIntervalSinceNow: 0.3];
    [[NSRunLoop currentRunLoop] runUntilDate: loopInterval];
    
}
/*!
 Utility method to fetched the fileName and return an NSData.
 
 @param fileName without extension of the IMAP formatted response file. "txt" will be appended to the file. and it is assumed to reside in the "answers" directory.
 
 @return an NSData of the file data.
 */
-(NSMutableData*) newDataFromFile: (NSString*) fileName {
    NSString *path = [self.testBundle pathForResource: fileName ofType: @"txt" inDirectory: @"answers"];
    
    NSMutableData *newData = [NSMutableData dataWithContentsOfFile: path];
    
    return newData;
}
#pragma mark - Begin Tests

- (void)testThatEnvironmentWorks {
    XCTAssertNotNil(self.model, @"no core data model");
    XCTAssertNotNil(self.store, @"no persistent store");
    XCTAssertNotNil(self.context, @"no managed object context");
    XCTAssertNotNil(self.selectedBox, @"no selectedBox");
    XCTAssertNotNil(self.clientStore.selectedMBox, @"no clientStore selectedBox");
    
    XCTAssertEqualObjects(kDefaultBoxPath, self.selectedBox.name, @"Wrong selectedBox name.");
}

- (void)testFetchBodyHeader {
    
    self.answer = NSStringFromSelector(_cmd);
    self.saveAnswers = NO;
//    self.responseMethodName = @"setMessage:";
    self.expectedParseResult = IMAPParseComplete;
    self.postEvalCheckMethod = @"fetchBodyHeaderPostEvalCheck";
    [self parseDataBuffer: [self newDataFromFile: @"uidfetchbodyheader"]];
}
-(void)fetchBodyHeaderPostEvalCheck {
    MBMessage* message = self.clientStore.selectedMBox.lastChangedMessage;
    XCTAssertEqualObjects(message.subject, @"A Home Depot gift card - our gift to you", @"Wrong spam flag.");
    XCTAssertEqualObjects(message.messageId, @"<20110731071954.4D14638781@mail.charcoalia.net> ", @"Wrong spam flag.");
    XCTAssertEqualObjects(message.xSpamScore, [NSNumber numberWithFloat: 3.936], @"Wrong spam score.");
    XCTAssertEqualObjects(message.xSpamLevel, @"***", @"Wrong spam level.");
    XCTAssertEqualObjects(message.xSpamFlag, @NO, @"Wrong spam flag.");
}

- (void)testRespFetchUidBodystructureWithPictures {
    self.answer = NSStringFromSelector(_cmd);
    self.expectedParseResult = IMAPParseComplete;
    self.saveAnswers = NO;
    self.postEvalCheckMethod = @"fetchUidBodystructureWithPicturesPostEvalCheck";
    [self parseDataBuffer: [self newDataFromFile: @"fetchBodyStructureWithPhotosAndAttachments"]];
}
-(void)fetchUidBodystructureWithPicturesPostEvalCheck {
    MBMessage* message = self.clientStore.selectedMBox.lastChangedMessage;
    XCTAssertTrue(message.subject==nil); // should be nil
    XCTAssertEqualObjects(message.uid, @759042);
    XCTAssertEqualObjects(message.rfc2822Size, @2606358);
    XCTAssertEqualObjects(message.isRecentFlag, @YES);
    
    MBMimeMessage* shouldBeMimeMessage = [[[[message childNodes]objectAtIndex:0]childNodes]objectAtIndex:1];
    XCTAssertTrue([shouldBeMimeMessage isKindOfClass: [MBMimeMessage class]]);//
    
    MBMimeImage* shouldBeMimeImage22 = [[[shouldBeMimeMessage.childNodes objectAtIndex: 0]childNodes]objectAtIndex:1];
    XCTAssertTrue([shouldBeMimeImage22 isKindOfClass: [MBMimeImage class]]);//
    XCTAssertTrue([shouldBeMimeImage22.bodyIndex isEqualToString: @"2.2"]);//
    XCTAssertTrue([shouldBeMimeImage22.filename isEqualToString: @"2007-2008 283.jpg"]);//
    XCTAssertTrue([shouldBeMimeMessage isKindOfClass: [MBMimeMessage class]]);//
    
    MBMimeImage* shouldBeMimeImage21 = [[[shouldBeMimeMessage.childNodes objectAtIndex: 0]childNodes]objectAtIndex:0];
    XCTAssertTrue([shouldBeMimeImage21 isKindOfClass: [MBMimeImage class]]);//
    XCTAssertTrue([shouldBeMimeImage21.bodyIndex isEqualToString: @"2.1"]);//
    XCTAssertTrue([shouldBeMimeImage21.filename isEqualToString: @"2007-2008 190.jpg"]);//

//    XCTAssertEqualObjects(message.messageId, @"");
//    XCTAssertEqualObjects(message.xSpamScore, [NSNumber numberWithFloat: 0], @"Wrong spam score.");
//    XCTAssertEqualObjects(message.xSpamLevel, @"***", @"Wrong spam level.");
//    XCTAssertEqualObjects(message.xSpamFlag, @NO, @"Wrong spam flag.");
}


#pragma mark IMAPResponseParserDelegate methods

-(void) parseComplete: (IMAPParsedResponse*) parsedResponse {
    //    NSLog(@"Tokens: %@",[parsedResponse.tokens debugDescription]);
    
    if (!self.saveAnswers) {
        [self checkAnswersFor: parsedResponse];
    } else {
        [self saveAnswer: parsedResponse.tokens.tokenArray As: self.answer];
        XCTFail(@"%@ - Can't check without a saved answer for comparison.", self.answer);
    }
    
    NSLog(@"\n[%@:%@ Command: %@; IMAPStatus: %@]; info %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), parsedResponse.command, [IMAPParsedResponse statusAsString: parsedResponse.status], parsedResponse.command.info);
    [parsedResponse evaluate];
    [self performSelector: NSSelectorFromString(self.postEvalCheckMethod)];
}

@end
