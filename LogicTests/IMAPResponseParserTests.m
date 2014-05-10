//
//  IMAPResponseTests.m
//  MailBoxes
//
//  Created by Taun Chapman on 9/7/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "IMAPResponseParser.h"
#import "IMAPParsedResponse.h"
#import "IMAPCommand.h"

#import "DDLog.h"




@class MBox;

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

/*!
 Class to test the IMAPResponseParser and IMAPParsedResponse. First we want to test the conversion of an IMAP formatted response string to a MBTokenTree. 
 We then want to test the delegate dispatching of the IMAPParsedResponse with the correct token arguments.
 */
@interface IMAPResponseParserTests : XCTestCase <IMAPResponseParserDelegate,IMAPParsedResponseDelegate, IMAPDataStore>

@property (nonatomic,strong,readwrite) MBox     *selectedMBox;
/*!
 IMAPResponseParser configured during setup.
 */
@property (strong) IMAPResponseParser           *parser;
@property (strong) NSBundle                     *testBundle;

/*!
 Is set by the IMAPParsedResponsDelegate methods to verify the correct method was called. Need to change to an array?
 */
@property (copy)     NSString                   *actionCalled;
/*!
 Set by the IMAPParsedResponseDelegate if the called method == the desired responseMethodName.
 */
@property (assign)  BOOL                        actionSuccess;
/*!
 Whether to save a plist representation of the response to the file system as a correct answer.
 */
@property (nonatomic,assign) BOOL               saveAnswers;
@property (nonatomic,strong) NSString           *answer;
/*!
 Set before evaluation to the IMAPParsedResponseDelegate method expected to be called. This is then compared to the actionCalled.
 */
@property (nonatomic,strong) NSString           *responseMethodName;
/*!
 Whether the parse should be complete, waiting, unexpected end, ...
 */
@property (nonatomic,assign) IMAPParseResult    expectedParseResult;

@end

@implementation IMAPResponseParserTests

- (void)setUp {
    [super setUp];
    
    // Set-up code here.
    _parser = [[IMAPResponseParser alloc] init];
    [_parser setBufferDelegate: self];
    [_parser setResponseDelegate: self];
    [_parser setDefaultDataStore: self];
    
    _actionSuccess = NO;
    
    _saveAnswers = NO;

    _testBundle = [NSBundle bundleWithIdentifier: @"com.moedae.LogicTests"];
}
- (void)tearDown {
    // Tear-down code here.
    [super tearDown];
}
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
    
    BOOL parseMatch = self.expectedParseResult == _parser.result;
    NSString* resultString = [IMAPResponseParser resultAsString: _parser.result];
    NSString* expectedString = [IMAPResponseParser resultAsString: self.expectedParseResult];
    XCTAssertTrue(parseMatch, @"Expected result: %@; Actual result: %@;", expectedString, resultString);
    
    NSMutableArray *tokens = [parsedResponse.tokens tokenArray];
    NSMutableArray *answerTokens = [self loadAnswersFor: self.answer];
    BOOL success = [tokens isEqualToArray: answerTokens];
    XCTAssertTrue(success, @"Parse tokens should be: \n%@; are: \n%@;", answerTokens, tokens);
}
/* sets up the necessary house keeping for the response to be able to evaluate the tokens */
//- (void)configDefaultResponse:(IMAPParsedResponse *)response {
//    response.delegate = self;
//    response.dataStore = self;
//    IMAPCommand* command = [[IMAPCommand alloc] initWithAtom: @""];
//    command.mboxFullPath = @"/test";
//    response.command = command;
//}
/*!
 Root utility method for starting the parsing.
 
 @param sampleResponseData IMAPResponse formatted data.
 @param answer             filename of answer file if the response is to be saved as a "correct" response for future tests.
 */
- (void) parseDataBuffer: (NSMutableData*) sampleResponseData {
    [_parser startParsing];
    [_parser addDataBuffer: sampleResponseData];
    
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

#pragma mark - begin tests

- (void)testParenRecursion {
    
    const char *line = "ENVELOPE (data1 (data2) data3) UID 1231 FLAGS (data1 data2)\r\n";
    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];
    
    self.responseMethodName =  nil;
    self.saveAnswers = NO;
    self.answer = NSStringFromSelector(_cmd);
    [self parseDataBuffer: newData];
}
- (void)testOkRespTextCapability {
    
    const char *line = "* OK [CAPABILITY IMAP4rev1 LITERAL+ SASL-IR LOGIN-REFERRALS ID ENABLE IDLE STARTTLS AUTH=PLAIN AUTH=LOGIN AUTH=CRAM-MD5 AUTH=X-PLAIN-SUBMIT] Dovecot\r\n";
    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];
    
    self.responseMethodName =  @"responseCapability:";
    self.expectedParseResult = IMAPParseComplete;
    self.saveAnswers = NO;
    self.answer = NSStringFromSelector(_cmd);
    [self parseDataBuffer: newData];
}
- (void)testRespCapability {
    
    const char *line = "* CAPABILITY IMAP4rev1 LITERAL+ SASL-IR LOGIN-REFERRALS ID ENABLE IDLE SORT SORT=DISPLAY THREAD=REFERENCES THREAD=REFS MULTIAPPEND CATENATE UNSELECT CHILDREN NAMESPACE UIDPLUS LIST-EXTENDED I18NLEVEL=1 CONDSTORE QRESYNC ESEARCH ESORT SEARCHRES WITHIN CONTEXT=SEARCH LIST-STATUS COMPRESS=DEFLATE X-FTS-COMPACT QUOTA URLAUTH\r\n";
    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];
    
    self.responseMethodName =  @"responseCapability:";
    self.expectedParseResult = IMAPParseComplete;
    self.saveAnswers = NO;
    self.answer = NSStringFromSelector(_cmd);
    [self parseDataBuffer: newData];
}

- (void)testRespFetchUidEnvelope {
    
    const char *line =  "* 120 FETCH (UID 120 FLAGS (\\Seen) ENVELOPE (\"Mon, 4 Feb 2008 06:17:46 -0000\" \"You've been granted access\" ((\"Borders Rewards Perks\" NIL \"Borders\" \"e.bordersstores.com\")) ((\"Borders Rewards Perks\" NIL \"Borders\" \"e.bordersstores.com\")) ((\"Borders Rewards Perks\" NIL \"support-b09pdbwaxsb41ra3r0ag2bq8we1dqm\" \"e.bordersstores.com\")) ((NIL NIL \"taun\" \"charcoalia.net\")) NIL NIL NIL \"<b09pdbwaxsb41ra3r0ag2bq8we1dqm.822905916.2082@mta45.e.bordersstores.com>\"))\r\n";
    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];
    
    self.responseMethodName =  @"setMessage:";
    self.expectedParseResult = IMAPParseComplete;
    self.saveAnswers = NO;
    self.answer = NSStringFromSelector(_cmd);
    [self parseDataBuffer: newData];
}
- (void)testRespFetchUidEnvelopeEmptyFlags {
    
    const char *line =  "* 120 FETCH (UID 120 FLAGS () ENVELOPE (\"Mon, 4 Feb 2008 06:17:46 -0000\" \"You've been granted access\" ((\"Borders Rewards Perks\" NIL \"Borders\" \"e.bordersstores.com\")) ((\"Borders Rewards Perks\" NIL \"Borders\" \"e.bordersstores.com\")) ((\"Borders Rewards Perks\" NIL \"support-b09pdbwaxsb41ra3r0ag2bq8we1dqm\" \"e.bordersstores.com\")) ((NIL NIL \"taun\" \"charcoalia.net\")) NIL NIL NIL \"<b09pdbwaxsb41ra3r0ag2bq8we1dqm.822905916.2082@mta45.e.bordersstores.com>\"))\r\n";
    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];
    
    self.responseMethodName =  @"setMessage:";
    self.expectedParseResult = IMAPParseComplete;
    self.saveAnswers = NO;
    self.answer = NSStringFromSelector(_cmd);
    [self parseDataBuffer: newData];
}
- (void)testRespFetchUidBodystructureSinglePart {
    
    const char *line =  "* 1072 FETCH (UID 1072 BODYSTRUCTURE (\"text\" \"plain\" (\"charset\" \"UTF-8\") NIL NIL \"7bit\" 2021 29 NIL NIL NIL NIL))\r\n";
    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];
    
    self.responseMethodName =  @"setMessage:";
    self.expectedParseResult = IMAPParseComplete;
    self.saveAnswers = NO;
    self.answer = NSStringFromSelector(_cmd);
    [self parseDataBuffer: newData];
}
- (void)testRespFetchUidBodystructureMultiPart {
    self.answer = NSStringFromSelector(_cmd);
    self.responseMethodName = @"setMessage:";
    self.expectedParseResult = IMAPParseComplete;
    self.saveAnswers = NO;
    [self parseDataBuffer: [self newDataFromFile: @"fetchBodystructureMultipartA"]];
}
- (void)testRespFetchUidBodystructureWithPictures {
    self.answer = NSStringFromSelector(_cmd);
    self.responseMethodName = @"setMessage:";
    self.expectedParseResult = IMAPParseComplete;
    self.saveAnswers = NO;
    [self parseDataBuffer: [self newDataFromFile: @"fetchBodyStructureWithPhotosAndAttachments"]];
}
- (void)testRespFetchUidBody2 {
    
    const char *line =  "* 1100 FETCH (UID 1100 BODY[2] \"This is the body data\")\r\n";
    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];
    
    self.responseMethodName =  @"setMessage:";
    self.expectedParseResult = IMAPParseComplete;
    self.saveAnswers = NO;
    self.answer = NSStringFromSelector(_cmd);
    [self parseDataBuffer: newData];
}
- (void)testRespFetchBodyPart2UID12499 {
    self.answer = NSStringFromSelector(_cmd);
    self.responseMethodName = @"setMessage:";
    self.expectedParseResult = IMAPParseComplete;
    self.saveAnswers = NO;
    [self parseDataBuffer: [self newDataFromFile: @"fetchBodyPart2UID12499"]];
}
- (void)testRespFetchBodyPart2CommandEnd {
    self.answer = NSStringFromSelector(_cmd);
    self.responseMethodName = @"setMessage:";
    self.expectedParseResult = IMAPParseComplete;
    self.saveAnswers = NO;
    [self parseDataBuffer: [self newDataFromFile: @"fetchBodyPart2CommandEnd"]];
}
#pragma message "ToDo: none of the multi-buffer tests work since async changes to Parser."
- (void)testRespFetchBodyPart2CommandEndMultiBuffer {
    
    self.answer = NSStringFromSelector(_cmd);
    self.saveAnswers = NO;
    [_parser startParsing];
    
    NSString *path0 = [self.testBundle pathForResource: @"fetchBodyPart2CommandEnd0" ofType: @"txt" inDirectory: @"answers"];
    NSString *path1 = [self.testBundle pathForResource: @"fetchBodyPart2CommandEnd1" ofType: @"txt" inDirectory: @"answers"];
    NSString *path2 = [self.testBundle pathForResource: @"fetchBodyPart2CommandEnd2" ofType: @"txt" inDirectory: @"answers"];
    
    NSMutableData *newData0 = [NSMutableData dataWithContentsOfFile: path0];
    NSMutableData *newData1 = [NSMutableData dataWithContentsOfFile: path1];
    NSMutableData *newData2 = [NSMutableData dataWithContentsOfFile: path2];
    
    
    [_parser addDataBuffer: newData0];
    [_parser addDataBuffer: newData1];
    [_parser addDataBuffer: newData2];
    
}
- (void)testRespFetchBodyPart2CommandEndIncompleteMultiBuffer {
    
    self.answer = NSStringFromSelector(_cmd);
    self.saveAnswers = NO;
    [_parser startParsing];
    
    NSString *path0 = [self.testBundle pathForResource: @"fetchBodyPart2CommandEnd0" ofType: @"txt" inDirectory: @"answers"];
    NSString *path1 = [self.testBundle pathForResource: @"fetchBodyPart2CommandEnd1" ofType: @"txt" inDirectory: @"answers"];
    NSString *path2 = [self.testBundle pathForResource: @"fetchBodyPart2CommandEnd2Incomplete" ofType: @"txt" inDirectory: @"answers"];
    
    NSMutableData *newData0 = [NSMutableData dataWithContentsOfFile: path0];
    NSMutableData *newData1 = [NSMutableData dataWithContentsOfFile: path1];
    NSMutableData *newData2 = [NSMutableData dataWithContentsOfFile: path2];
    
    
    [_parser addDataBuffer: newData0];
    [_parser addDataBuffer: newData1];
    [_parser addDataBuffer: newData2];
}

- (void)testFetchWithLiteral {
    self.answer = NSStringFromSelector(_cmd);
    self.responseMethodName = nil;
    self.expectedParseResult = IMAPParseComplete;
    self.saveAnswers = NO;
    [self parseDataBuffer: [self newDataFromFile: @"fetchresponse"]];
}
- (void)testFetchLW200 {
    
    self.answer = NSStringFromSelector(_cmd);
    self.saveAnswers = NO;
    self.responseMethodName = @"commandDone";
    self.expectedParseResult = IMAPParseComplete;
    [self parseDataBuffer: [self newDataFromFile: @"fetch200Response"]];
}
- (void)testFetchRFC822Header {
    
    self.answer = NSStringFromSelector(_cmd);
    self.saveAnswers = NO;
    self.responseMethodName = @"setMessage:";
    self.expectedParseResult = IMAPParseComplete;
    [self parseDataBuffer: [self newDataFromFile: @"uidfetchrfc822header"]];
}
//uidfetchbodyheader.txt
- (void)testFetchBodyHeader {
    
    self.answer = NSStringFromSelector(_cmd);
    self.saveAnswers = NO;
    self.responseMethodName = @"setMessage:";
    self.expectedParseResult = IMAPParseComplete;
    [self parseDataBuffer: [self newDataFromFile: @"uidfetchbodyheader"]];
}
- (void)testFetchRFC822Multipart {
    
    self.answer = NSStringFromSelector(_cmd);
    self.saveAnswers = NO;
    self.responseMethodName = @"commandDone";
    self.expectedParseResult = IMAPParseComplete;
    [self parseDataBuffer: [self newDataFromFile: @"sampleFetchRFC2822"]];
}



- (void)testFetchGrandMastersSampleRFC822Header {
    
    self.answer = NSStringFromSelector(_cmd);
    self.saveAnswers = NO;
    self.responseMethodName = @"commandDone";
    self.expectedParseResult = IMAPParseComplete;
    [self parseDataBuffer: [self newDataFromFile: @"GrandMastersSampleHeader1"]];
}

- (void)testOkPermanentFlags {
    
    const char *line = "* OK [PERMANENTFLAGS (\\Answered \\Flagged \\Deleted \\Seen \\Draft ToDo $Forwarded Forwarded Knowledge Soccer PADA MAYER CISVCommWork:FLAG9 InvoiceReceipt Redirected \\*)] Flags permitted.\r\n";
    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];
    
    self.responseMethodName = nil;
    self.answer = NSStringFromSelector(_cmd);
    self.saveAnswers = NO;
    [self parseDataBuffer: newData];
}

- (void)testHalfBufferPlusHalfBuffer {
    
    self.answer = NSStringFromSelector(_cmd);
    self.saveAnswers = NO;
    self.responseMethodName = nil;
    [_parser startParsing];
    
    const char *line = "* OK [PERMANENTFLAGS (\\Answered \\Flagged \\Deleted \\Seen \\Draft ToDo $Forwarded ";
    const char *line2 = "Forwarded Knowledge Soccer PADA MAYER CISVCommWork:FLAG9 InvoiceReceipt Redirected \\*)] Flags permitted.\r\n";
    
    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];
    NSMutableData *newData2 = [[NSMutableData alloc] initWithBytes: line2 length: strlen(line2)];
    
    [_parser addDataBuffer: newData];
    [_parser addDataBuffer: newData2];
    
}

- (void)testRangeOfStringEnclosedByWithBadString {
    
    const char *line = "ENVELOPE (data1 (data2) data3 UID 1231 FLAGS (data1 data2)\r\n";
    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];

    self.answer = NSStringFromSelector(_cmd);
    self.saveAnswers = NO;
    self.responseMethodName = nil;
    [self parseDataBuffer: newData];
}

- (void)testXList1Line {
    
    const char *line = "* XLIST (\\HasNoChildren) \"/\" \"admin@moedae.com's Inbox/mz1.moedaworks.com\"\r\n";
    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];
    
    self.responseMethodName = @"setMailBoxFlags:";
    self.expectedParseResult = IMAPParseComplete;
    self.saveAnswers = NO;
    self.answer = NSStringFromSelector(_cmd);
    [self parseDataBuffer: newData];
}
- (void)testOkUnseen1Line {
    
    const char *line = "* OK [UNSEEN 19] First unseen.\r\n";
    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];
    
    self.responseMethodName = @"responseUnseen:";
    self.expectedParseResult = IMAPParseComplete;
    self.saveAnswers = NO;
    self.answer = NSStringFromSelector(_cmd);
    [self parseDataBuffer: newData];
}
- (void)testOkUidvalidity1Line {
    
    const char *line = "* OK [UIDVALIDITY 1312094147] UIDs valid\r\n";
    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];
    
    self.responseMethodName = @"responseUidvalidity:";
    self.expectedParseResult = IMAPParseComplete;
    self.saveAnswers = NO;
    self.answer = NSStringFromSelector(_cmd);
    [self parseDataBuffer: newData];
}
- (void)testOkUidnext1Line {
    
    const char *line = "* OK [UIDNEXT 12598] Predicted next UID\r\n";
    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];
    
    self.responseMethodName = @"responseUidnext:";
    self.expectedParseResult = IMAPParseComplete;
    self.saveAnswers = NO;
    self.answer = NSStringFromSelector(_cmd);
    [self parseDataBuffer: newData];
}
- (void)testXList1LineNoLineFeed {
    
    const char *line = "* XLIST (\\HasNoChildren) \"/\" \"admin@moedae.com's Inbox/mz1.moedaworks.com\"\r";
    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];
    
    self.responseMethodName = @"responseXlist:";
    self.expectedParseResult = IMAPParseComplete;
    self.saveAnswers = NO;
    self.answer = NSStringFromSelector(_cmd);
    [self parseDataBuffer: newData];
}

- (void)testDoneOkFetchCompleted {
    
    const char *line = "a0003 OK Fetch completed.\r\n";
    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];
    
    self.responseMethodName = @"commandDone:";
    self.expectedParseResult = IMAPParseComplete;
    self.saveAnswers = NO;
    self.answer = NSStringFromSelector(_cmd);
    [self parseDataBuffer: newData];
}

#pragma mark delegate response methods
-(void) parseComplete: (IMAPParsedResponse*) parsedResponse {
//    NSLog(@"Tokens: %@",[parsedResponse.tokens debugDescription]);
    
    if (!self.saveAnswers) {
        [self checkAnswersFor: parsedResponse];
    } else {
        [self saveAnswer: parsedResponse.tokens.tokenArray As: self.answer];
        XCTFail(@"%@ - Can't check without a saved answer for comparison.", self.answer);
    }
    
    if (self.responseMethodName!=nil) {
        NSLog(@"\n[%@:%@ Command: %@; IMAPStatus: %@]; info %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), parsedResponse.command, [IMAPParsedResponse statusAsString: parsedResponse.status], parsedResponse.command.info);
        [parsedResponse evaluate];
    }
}
-(void) parseWaiting: (IMAPParsedResponse*) parsedResponse {
    DDLogVerbose(@"[%@:%@ Tag: %@; IMAPStatus: %@]; info %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), parsedResponse.command.tag, [IMAPParsedResponse statusAsString: parsedResponse.status], parsedResponse.command.info);
}
-(void) parseUnexpectedEnd: (IMAPParsedResponse*) parsedResponse {
    DDLogVerbose(@"[%@:%@ Tag: %@; IMAPStatus: %@]; info %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), parsedResponse.command.tag, [IMAPParsedResponse statusAsString: parsedResponse.status], parsedResponse.command.info);
}
-(void) parseError: (IMAPParsedResponse*) parsedResponse {
    DDLogVerbose(@"[%@:%@ Tag: %@; IMAPStatus: %@]; info %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), parsedResponse.command.tag, [IMAPParsedResponse statusAsString: parsedResponse.status], parsedResponse.command.info);
}
-(void) parseTimeout: (IMAPParsedResponse*) parsedResponse {
    DDLogVerbose(@"[%@:%@ Tag: %@; IMAPStatus: %@]; info %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), parsedResponse.command.tag, [IMAPParsedResponse statusAsString: parsedResponse.status], parsedResponse.command.info);
}

-(void) responseBye: (IMAPParsedResponse*) parsedResponse {
    
}
-(void) responseUnknown: (IMAPParsedResponse*) parsedResponse {
    
}
-(void) responseFlags: (IMAPParsedResponse*) parsedResponse {
}
-(void) responseXlist: (IMAPParsedResponse*) parsedResponse {
    self.actionCalled = NSStringFromSelector(_cmd);
}
-(void) responseList: (IMAPParsedResponse*) parsedResponse {
    [self responseXlist: parsedResponse];
}
-(void) responseLsub: (IMAPParsedResponse*) parsedResponse {}
-(void) responseSearch: (IMAPParsedResponse*) parsedResponse {}
-(void) responseStatus: (IMAPParsedResponse*) parsedResponse {}
-(void) responseExists: (IMAPParsedResponse*) parsedResponse {
    
}
-(void) responseRecent: (IMAPParsedResponse*) parsedResponse {
    
}

// Message responses
-(void) responseExpunge: (IMAPParsedResponse*) parsedResponse {
    
}
-(void) responseFetch: (IMAPParsedResponse*) parsedResponse {
    //IMAPResponseBuffer *passedParser = (IMAPResponseBuffer *)response;
    //MBTokenTree *tokens = passedParser.tokens;
    //DDLogVerbose(@"delegate method: %@ - parser tokens: %@", NSStringFromSelector(_cmd), tokens);
    self.actionCalled = NSStringFromSelector(_cmd);
}

// Resp-text-codes
-(void) responseCapability: (IMAPParsedResponse*) parsedResponse {
//    IMAPResponseBuffer *passedParser = (IMAPResponseBuffer *)response;
//    MBTokenTree *tokens = passedParser.tokens;
//    DDLogVerbose(@"delegate method: %@ - parser tokens: %@", NSStringFromSelector(_cmd), tokens);
    self.actionCalled = NSStringFromSelector(_cmd);
}
-(void) responseComplete: (IMAPParsedResponse*) parsedResponse {
    //    IMAPResponseBuffer *passedParser = (IMAPResponseBuffer *)response;
    //    MBTokenTree *tokens = passedParser.tokens;
    //    DDLogVerbose(@"delegate method: %@ - parser tokens: %@", NSStringFromSelector(_cmd), tokens);
    self.actionCalled = NSStringFromSelector(_cmd);
}
-(void) responseAlert: (IMAPParsedResponse*) parsedResponse {}
-(void) responseIgnore: (IMAPParsedResponse*) parsedResponse {}
-(void) responseBadcharset: (IMAPParsedResponse*) parsedResponse {}
-(void) responseParse: (IMAPParsedResponse*) parsedResponse {}
-(void) responsePermanentflags: (IMAPParsedResponse*) parsedResponse {}
-(void) responseReadOnly: (IMAPParsedResponse*) parsedResponse {}
-(void) responseReadWrite: (IMAPParsedResponse*) parsedResponse {}
-(void) responseTrycreate: (IMAPParsedResponse*) parsedResponse {}

-(void) responseUidnext: (IMAPParsedResponse*) parsedResponse {
//    IMAPResponseBuffer *passedParser = (IMAPResponseBuffer *)response;
//    MBTokenTree *tokens = passedParser.tokens;
//    DDLogVerbose(@"delegate method: %@ - parser tokens: %@", NSStringFromSelector(_cmd), tokens);
    self.actionCalled = NSStringFromSelector(_cmd);
}

-(void) responseUidvalidity: (IMAPParsedResponse*) parsedResponse {
//    IMAPResponseBuffer *passedParser = (IMAPResponseBuffer *)response;
//    MBTokenTree *tokens = passedParser.tokens;
//    DDLogVerbose(@"delegate method: %@ - parser tokens: %@", NSStringFromSelector(_cmd), tokens);
    self.actionCalled = NSStringFromSelector(_cmd);
}

-(void) responseUnseen: (IMAPParsedResponse*) parsedResponse {
//    IMAPResponseBuffer *passedParser = (IMAPResponseBuffer *)response;
//    MBTokenTree *tokens = passedParser.tokens;
//    DDLogVerbose(@"delegate method: %@ - parser tokens: %@", NSStringFromSelector(_cmd), tokens);
    self.actionCalled = NSStringFromSelector(_cmd);
}

-(void) commandDone: (IMAPParsedResponse*) parsedResponse {
//    IMAPResponseBuffer *passedParser = (IMAPResponseBuffer *)response;
//    MBTokenTree *tokens = passedParser.tokens;
//    DDLogVerbose(@"delegate method: %@ - parser tokens: %@", NSStringFromSelector(_cmd), tokens);
    DDLogVerbose(@"[%@:%@ Tag: %@; IMAPStatus: %@]; info %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), parsedResponse.command.tag, [IMAPParsedResponse statusAsString: parsedResponse.status], parsedResponse.command.info);
    self.actionCalled = NSStringFromSelector(_cmd);
}

-(void) commandContinue: (IMAPParsedResponse*) parsedResponse {
//    IMAPResponseBuffer *passedParser = (IMAPResponseBuffer *)response;
//    MBTokenTree *tokens = passedParser.tokens;
//    DDLogVerbose(@"delegate method: %@ - parser tokens: %@", NSStringFromSelector(_cmd), tokens);
    self.actionCalled = NSStringFromSelector(_cmd);
}

#pragma mark - IMAPClientStore Protocol

-(NSSet*) allUIDsForSelectedMailBox {
    return nil;
}

-(NSSet*) allCachedUIDsForSelectedMailBox {
    return nil;
}

-(NSSet*) allCachedUIDsNotFullyCachedForSelectedMailBox {
    return nil;
}

-(BOOL) setMailBoxReadOnly: (NSString *) fullPath {
    
    BOOL success = [self.responseMethodName isEqualToString: @"setMailBoxReadOnly:"];
    XCTAssertTrue(success, @"Response method called should be: %@, was: %@", self.responseMethodName, self.actionCalled);
    return success;
}
-(BOOL) setMailBoxReadWrite: (NSString *) fullPath {
    
    BOOL success = [self.responseMethodName isEqualToString: @"setMailBoxReadWrite:"];
    XCTAssertTrue(success, @"Response method called should be: %@, was: %@", self.responseMethodName, self.actionCalled);
    return success;
}
-(BOOL) setMailBoxFlags: (NSArray *) flagTokens onPath:     (NSString *) fullPath withSeparator: (NSString *) aSeparator {
    
    BOOL success = [self.responseMethodName isEqualToString: @"setMailBoxFlags:"];
    XCTAssertTrue(success, @"Response method called should be: %@, was: %@", self.responseMethodName, self.actionCalled);
    return success;
}

-(BOOL) setMailBox: (NSString *) fullPath       AvailableFlags:     (NSArray *) flagTokens {
    
    BOOL success = [self.responseMethodName isEqualToString: @"AvailableFlags:"];
    XCTAssertTrue(success, @"Response method called should be: %@, was: %@", self.responseMethodName, self.actionCalled);
    return success;
}
-(BOOL) setMailBox: (NSString *) fullPath       PermanentFlags:     (NSArray *) flagTokens {
    
    BOOL success = [self.responseMethodName isEqualToString: @"PermanentFlags:"];
    XCTAssertTrue(success, @"Response method called should be: %@, was: %@", self.responseMethodName, self.actionCalled);
    return success;
}
-(BOOL) setMailBox: (NSString *) fullPath       serverHighestmodseq: (NSNumber *) theCount {
    
    BOOL success = [self.responseMethodName isEqualToString: @"serverHighestmodseq:"];
    XCTAssertTrue(success, @"Response method called should be: %@, was: %@", self.responseMethodName, self.actionCalled);
    return success;
}
-(BOOL) setMailBox: (NSString *) fullPath       serverMessageCount: (NSNumber *) theCount {
    
    BOOL success = [self.responseMethodName isEqualToString: @"serverMessageCount:"];
    XCTAssertTrue(success, @"Response method called should be: %@, was: %@", self.responseMethodName, self.actionCalled);
    return success;
}
-(BOOL) setMailBox: (NSString *) fullPath       serverRecentCount:  (NSNumber *) theCount {
    
    BOOL success = [self.responseMethodName isEqualToString: @"serverRecentCount:"];
    XCTAssertTrue(success, @"Response method called should be: %@, was: %@", self.responseMethodName, self.actionCalled);
    return success;
}
-(BOOL) setMailBox: (NSString *) fullPath       Uidnext:            (NSNumber *) uidNext {
    
    BOOL success = [self.responseMethodName isEqualToString: @"Uidnext:"];
    XCTAssertTrue(success, @"Response method called should be: %@, was: %@", self.responseMethodName, self.actionCalled);
    return success;
}
-(BOOL) setMailBox: (NSString *) fullPath       Uidvalidity:        (NSNumber *) uidValidity {
    
    BOOL success = [self.responseMethodName isEqualToString: @"Uidvalidity:"];
    XCTAssertTrue(success, @"Response method called should be: %@, was: %@", self.responseMethodName, self.actionCalled);
    return success;
}
-(BOOL) setMailBox: (NSString *) fullPath       serverUnseen:       (NSNumber *) unseen {
    
    BOOL success = [self.responseMethodName isEqualToString: @"serverUnseen:"];
    XCTAssertTrue(success, @"Response method called should be: %@, was: %@", self.responseMethodName, self.actionCalled);
    return success;
}

-(MBox *) selectMailBox: (NSString *) fullPath {
    return nil;
}

-(void) save {
    
}

-(MBMessage*) messageForObjectID: (NSManagedObjectID*) messageID {
    return nil;
}

-(NSNumber*) lowestUID {
    return @0;
}

-(BOOL) selectedMailBoxDeleteAllMessages:  (NSError**) error {
    
    BOOL result = YES;
    
    return result;
}


/*!
 All of the following message methods work on the messages in the selectedMBox.
 
 @param uid NSNumber of message UID
 @param aDictionary NSDictionary of ?
 */
-(BOOL) setMessage: (NSNumber*) uid propertiesFromDictionary: (NSDictionary*) aDictionary {
    
    BOOL success = [self.responseMethodName isEqualToString: @"setMessage:"];
    XCTAssertTrue(success, @"Response method called should be: %@, was: %@", self.responseMethodName, self.actionCalled);
    return success;
}
-(BOOL) newMessage: (NSNumber*) uid propertiesFromDictionary: (NSDictionary*) aDictionary {
    
    BOOL success = [self.responseMethodName isEqualToString: @"setMessage:"];
    XCTAssertTrue(success, @"Response method called should be: %@, was: %@", self.responseMethodName, self.actionCalled);
    return success;
}


@end
