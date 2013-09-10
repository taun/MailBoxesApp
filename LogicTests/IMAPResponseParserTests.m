//
//  IMAPResponseTests.m
//  MailBoxes
//
//  Created by Taun Chapman on 9/7/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

#import "IMAPResponseParserTests.h"
#import "IMAPResponseBuffer.h"
#import "IMAPResponse.h"
#import "IMAPCommand.h"
#import "MBTokenTree.h"

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation IMAPResponseParserTests

@synthesize parser;
@synthesize actionCalled;


- (void)setUp {
    [super setUp];
    
    // Set-up code here.
    parser = [[IMAPResponseBuffer alloc] init];
    [parser setDelegate: self];
    
    saveAnswers = NO;

    testBundle = [NSBundle bundleWithIdentifier: @"com.moedae.LogicTests"];
}
- (void)tearDown {
    // Tear-down code here.
    [super tearDown];
}

-(void) saveAnswer: (NSMutableArray *) tokens As: (NSString *) methodName {
    NSString *fileName = [NSString stringWithFormat: @"%@.archive", methodName];
    NSString *archivePath = [NSHomeDirectory() stringByAppendingPathComponent: fileName];
    [NSKeyedArchiver archiveRootObject: tokens toFile: archivePath];
}
-(NSMutableArray *) loadAnswersFor: (NSString *) methodName {
    NSString *path = [testBundle pathForResource: methodName ofType: @"archive" inDirectory: @"answers"];
    
    NSMutableArray *answerTokens = [NSKeyedUnarchiver unarchiveObjectWithFile: path];
    
    return answerTokens;
}

- (void)configDefaultResponse:(IMAPResponse *)response {
    response.delegate = self;
    response.clientStore = self;
    IMAPCommand* command = [[IMAPCommand alloc] initWithAtom: @""];
    command.mboxFullPath = @"/test";
    response.command = command;
}

- (void) parseDataBuffer: (NSMutableData*) sampleResponseData responseMethod: (NSString*) methodName saveAnswer: (BOOL) saving answer: (NSString*) answer {
    [parser addDataBuffer: sampleResponseData];
    
    IMAPResponse* response = nil;
    IMAPParseResult result = [self.parser parseBuffer: &response];
    
    NSMutableArray *tokens = [response.tokens tokenArray];
    
    if (saving) {
        [self saveAnswer: tokens As: answer];
    }
    
    NSMutableArray *answerTokens = [self loadAnswersFor: answer];
    
    XCTAssertEqualObjects(tokens, answerTokens, @"Parse result: %i", result);
    XCTAssertTrue(result == IMAPParseComplete, @"Parse result: %i", result);
    
    if (methodName!=nil) {
        [self configDefaultResponse:response];
        [response evaluate];
        XCTAssertTrue([methodName compare: self.actionCalled] == NSOrderedSame, @"Response method called should be: %@, was: %@", methodName, self.actionCalled);
    }
    // need to assert result of above
    // set an ivar in delegate method with name and arguments passed to delegate method
    // compare to desired.
}

- (void) parseFile: (NSString*) fileName responseMethod: (NSString*) methodName saveAnswer: (BOOL) saving answer: (NSString*) answer {
    
    NSString *path = [testBundle pathForResource: fileName ofType: @"txt" inDirectory: @"answers"];
    
    NSMutableData *newData = [NSMutableData dataWithContentsOfMappedFile: path];
    
    [self parseDataBuffer: newData responseMethod: methodName saveAnswer: saving answer: (NSString*) answer];
}


#pragma mark - begin tests

- (void)testParenRecursion {
    
    const char *line = "ENVELOPE (data1 (data2) data3) UID 1231 FLAGS (data1 data2)\r\n";
    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];
    
    [self parseDataBuffer: newData responseMethod: nil saveAnswer: saveAnswers answer: NSStringFromSelector(_cmd)];
}
- (void)testOkRespTextCapability {
    
    const char *line = "* OK [CAPABILITY IMAP4rev1 LITERAL+ SASL-IR LOGIN-REFERRALS ID ENABLE IDLE STARTTLS AUTH=PLAIN AUTH=LOGIN AUTH=CRAM-MD5 AUTH=X-PLAIN-SUBMIT] Dovecot\r\n";
    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];
    
    [self parseDataBuffer: newData responseMethod: @"responseCapability:" saveAnswer: saveAnswers answer: NSStringFromSelector(_cmd)];
}
- (void)testRespCapability {
    
    const char *line = "* CAPABILITY IMAP4rev1 LITERAL+ SASL-IR LOGIN-REFERRALS ID ENABLE IDLE SORT SORT=DISPLAY THREAD=REFERENCES THREAD=REFS MULTIAPPEND CATENATE UNSELECT CHILDREN NAMESPACE UIDPLUS LIST-EXTENDED I18NLEVEL=1 CONDSTORE QRESYNC ESEARCH ESORT SEARCHRES WITHIN CONTEXT=SEARCH LIST-STATUS COMPRESS=DEFLATE X-FTS-COMPACT QUOTA URLAUTH\r\n";
    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];
    
    [self parseDataBuffer: newData responseMethod: @"responseCapability:" saveAnswer: saveAnswers answer: NSStringFromSelector(_cmd)];
}

- (void)testRespFetchUidEnvelope {
    
    const char *line =  "* 120 FETCH (UID 120 FLAGS (\\Seen) ENVELOPE (\"Mon, 4 Feb 2008 06:17:46 -0000\" \"You've been granted access\" ((\"Borders Rewards Perks\" NIL \"Borders\" \"e.bordersstores.com\")) ((\"Borders Rewards Perks\" NIL \"Borders\" \"e.bordersstores.com\")) ((\"Borders Rewards Perks\" NIL \"support-b09pdbwaxsb41ra3r0ag2bq8we1dqm\" \"e.bordersstores.com\")) ((NIL NIL \"taun\" \"charcoalia.net\")) NIL NIL NIL \"<b09pdbwaxsb41ra3r0ag2bq8we1dqm.822905916.2082@mta45.e.bordersstores.com>\"))\r\n";

    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];
    
    [self parseDataBuffer: newData responseMethod: @"setMessage:" saveAnswer: saveAnswers answer: NSStringFromSelector(_cmd)];
}
- (void)testRespFetchUidEnvelopeEmptyFlags {
    
    const char *line =  "* 120 FETCH (UID 120 FLAGS () ENVELOPE (\"Mon, 4 Feb 2008 06:17:46 -0000\" \"You've been granted access\" ((\"Borders Rewards Perks\" NIL \"Borders\" \"e.bordersstores.com\")) ((\"Borders Rewards Perks\" NIL \"Borders\" \"e.bordersstores.com\")) ((\"Borders Rewards Perks\" NIL \"support-b09pdbwaxsb41ra3r0ag2bq8we1dqm\" \"e.bordersstores.com\")) ((NIL NIL \"taun\" \"charcoalia.net\")) NIL NIL NIL \"<b09pdbwaxsb41ra3r0ag2bq8we1dqm.822905916.2082@mta45.e.bordersstores.com>\"))\r\n";
    
    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];
    
    [self parseDataBuffer: newData responseMethod: @"setMessage:" saveAnswer: saveAnswers answer: NSStringFromSelector(_cmd)];
}
- (void)testRespFetchUidBodystructureSinglePart {
    
    const char *line =  "* 1072 FETCH (UID 1072 BODYSTRUCTURE (\"text\" \"plain\" (\"charset\" \"UTF-8\") NIL NIL \"7bit\" 2021 29 NIL NIL NIL NIL))\r\n";
    
    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];
    
    [self parseDataBuffer: newData responseMethod: @"setMessage:" saveAnswer: NO answer: NSStringFromSelector(_cmd)];
}
- (void)testRespFetchUidBodystructureMultiPart {
    
    NSString *path = [testBundle pathForResource: @"fetchBodystructureMultipartA" ofType: @"txt" inDirectory: @"answers"];
    
    NSMutableData *newData = [NSMutableData dataWithContentsOfMappedFile: path];
    
    [self parseDataBuffer: newData responseMethod: @"setMessage:" saveAnswer: NO answer: NSStringFromSelector(_cmd)];
}
- (void)testRespFetchUidBody2 {
    
    const char *line =  "* 1100 FETCH (UID 1100 BODY[2] \"This is the body data\")\r\n";
    
    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];
    
    [self parseDataBuffer: newData responseMethod: nil saveAnswer: saveAnswers answer: NSStringFromSelector(_cmd)];
}
- (void)testRespFetchBodyPart2UID12499 {
    [self parseFile: @"fetchBodyPart2UID12499" responseMethod: @"setMessage" saveAnswer: NO answer: NSStringFromSelector(_cmd)];
}
- (void)testRespFetchBodyPart2CommandEnd {
    [self parseFile: @"fetchBodyPart2CommandEnd" responseMethod: @"setMessage" saveAnswer: NO answer: NSStringFromSelector(_cmd)];
}
- (void)testRespFetchBodyPart2CommandEndMultiBuffer {
    
    NSString *path0 = [testBundle pathForResource: @"fetchBodyPart2CommandEnd0" ofType: @"txt" inDirectory: @"answers"];
    NSString *path1 = [testBundle pathForResource: @"fetchBodyPart2CommandEnd1" ofType: @"txt" inDirectory: @"answers"];
    NSString *path2 = [testBundle pathForResource: @"fetchBodyPart2CommandEnd2" ofType: @"txt" inDirectory: @"answers"];
    
    NSMutableData *newData0 = [NSMutableData dataWithContentsOfFile: path0];
    NSMutableData *newData1 = [NSMutableData dataWithContentsOfFile: path1];
    NSMutableData *newData2 = [NSMutableData dataWithContentsOfFile: path2];
    
    
    [parser addDataBuffer: newData0];
    [parser addDataBuffer: newData1];
    [parser addDataBuffer: newData2];
    
    IMAPResponse* response = nil;
    IMAPParseResult result = [self.parser parseBuffer: &response];
    
    NSMutableArray *tokens = [response.tokens tokenArray];
    
    if (saveAnswers) {
        [self saveAnswer: tokens As: NSStringFromSelector(_cmd)];
    }
    
    NSMutableArray *answerTokens = [self loadAnswersFor: NSStringFromSelector(_cmd)];
    
    XCTAssertEqualObjects(tokens, answerTokens, @"Parse result: %i", result);
    XCTAssertTrue(result == IMAPParseComplete, @"Parse result: %i", result);
}
- (void)testRespFetchBodyPart2CommandEndIncompleteMultiBuffer {
    
    NSString *path0 = [testBundle pathForResource: @"fetchBodyPart2CommandEnd0" ofType: @"txt" inDirectory: @"answers"];
    NSString *path1 = [testBundle pathForResource: @"fetchBodyPart2CommandEnd1" ofType: @"txt" inDirectory: @"answers"];
    NSString *path2 = [testBundle pathForResource: @"fetchBodyPart2CommandEnd2Incomplete" ofType: @"txt" inDirectory: @"answers"];
    
    NSMutableData *newData0 = [NSMutableData dataWithContentsOfFile: path0];
    NSMutableData *newData1 = [NSMutableData dataWithContentsOfFile: path1];
    NSMutableData *newData2 = [NSMutableData dataWithContentsOfFile: path2];
    
    
    [parser addDataBuffer: newData0];
    [parser addDataBuffer: newData1];
    [parser addDataBuffer: newData2];
    
    IMAPResponse* response = nil;
    IMAPParseResult result = [self.parser parseBuffer: &response];
    
    NSMutableArray *tokens = [response.tokens tokenArray];
    
    if (saveAnswers) {
        [self saveAnswer: tokens As: NSStringFromSelector(_cmd)];
    }
    
    NSMutableArray *answerTokens = [self loadAnswersFor: NSStringFromSelector(_cmd)];
    
    XCTAssertEqualObjects(tokens, answerTokens, @"Parse result: %i", result);
    XCTAssertTrue(result == IMAPParseComplete, @"Parse result: %i", result);
}

- (void)testFetchWithLiteral {
    [self parseFile: @"fetchresponse" responseMethod: nil saveAnswer: saveAnswers answer: NSStringFromSelector(_cmd)];
}
- (void)testFetchLW200 {
    
    NSString *path = [testBundle pathForResource: @"fetch200Response" ofType: @"txt" inDirectory: @"answers"];
    
    NSMutableData *newData = [[NSMutableData alloc] initWithContentsOfFile: path];
    
    [parser addDataBuffer: newData];
    
    IMAPResponse* response = nil;
    IMAPParseResult result;
    //MBTokenTree *tokens = nil;
    NSString *responseMethodName = @"commandDone:";
    int i = 1;
    
    do {
        response = nil;
        result = [self.parser parseBuffer: &response];
        //tokens = parser.tokens;
        if (result == IMAPParseComplete) {
            [self configDefaultResponse:response];
            [response evaluate];
        }
        i++;
    } while ([self.actionCalled compare: responseMethodName] != NSOrderedSame && i < 201);
    
    
    XCTAssertTrue(result == IMAPParseComplete, @"Parse result: %i", result);
}
- (void)testFetchRFC822Header {
    
    NSString *path = [testBundle pathForResource: @"uidfetchrfc822header" ofType: @"txt" inDirectory: @"answers"];
    
    NSMutableData *newData = [[NSMutableData alloc] initWithContentsOfFile: path];
    
    [parser addDataBuffer: newData];
    
    IMAPResponse* response = nil;
    IMAPParseResult result;
    //MBTokenTree *tokens = nil;
    NSString *responseMethodName = @"commandDone:";
    int i = 1;
    
    do {
        response = nil;
        result = [self.parser parseBuffer: &response];
        //tokens = parser.tokens;
        if (result == IMAPParseComplete) {
            [self configDefaultResponse:response];
            [response evaluate];
        }
        i++;
    } while ([self.actionCalled compare: responseMethodName] != NSOrderedSame && i < 201);
    
    
    XCTAssertTrue(result == IMAPParseComplete, @"Parse result: %i", result);
}

- (void)testOkPermanentFlags {
    
    const char *line = "* OK [PERMANENTFLAGS (\\Answered \\Flagged \\Deleted \\Seen \\Draft ToDo $Forwarded Forwarded Knowledge Soccer PADA MAYER CISVCommWork:FLAG9 InvoiceReceipt Redirected \\*)] Flags permitted.\r\n";
    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];
    
    [self parseDataBuffer: newData responseMethod: nil saveAnswer: saveAnswers answer: NSStringFromSelector(_cmd)];
}

- (void)testHalfBufferPlusHalfBuffer {
    
    const char *line = "* OK [PERMANENTFLAGS (\\Answered \\Flagged \\Deleted \\Seen \\Draft ToDo $Forwarded ";
    const char *line2 = "Forwarded Knowledge Soccer PADA MAYER CISVCommWork:FLAG9 InvoiceReceipt Redirected \\*)] Flags permitted.\r\n";
    
    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];
    NSMutableData *newData2 = [[NSMutableData alloc] initWithBytes: line2 length: strlen(line2)];
    
    [parser addDataBuffer: newData];
    [parser addDataBuffer: newData2];
    
    IMAPResponse* response = nil;
    IMAPParseResult result = [self.parser parseBuffer: &response];
    
    NSMutableArray *tokens = [response.tokens tokenArray];
    
    if (saveAnswers) {
        [self saveAnswer: tokens As: NSStringFromSelector(_cmd)];
    }
    
    NSMutableArray *answerTokens = [self loadAnswersFor: NSStringFromSelector(_cmd)];
    
    XCTAssertEqualObjects(tokens, answerTokens, @"Parse result: %i", result);
    XCTAssertTrue(result == IMAPParseComplete, @"Parse result: %i", result);
}

- (void)testRangeOfStringEnclosedByWithBadString {
    
    const char *line = "ENVELOPE (data1 (data2) data3 UID 1231 FLAGS (data1 data2)\r\n";
    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];
    
    [parser addDataBuffer: newData];
    
    IMAPResponse* response = nil;
    IMAPParseResult result = [self.parser parseBuffer: &response];
        
    XCTAssertTrue(result == IMAPParseUnexpectedEnd, @"Parse result: %i", result);
}

- (void)testXList1Line {
    
    const char *line = "* XLIST (\\HasNoChildren) \"/\" \"admin@moedae.com's Inbox/mz1.moedaworks.com\"\r\n";
    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];
    
    [self parseDataBuffer: newData responseMethod: @"setMailBoxFlags:" saveAnswer: saveAnswers answer: NSStringFromSelector(_cmd)];
}
- (void)testOkUnseen1Line {
    
    const char *line = "* OK [UNSEEN 19] First unseen.\r\n";
    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];
    
    [self parseDataBuffer: newData responseMethod: @"serverUnseen:" saveAnswer: saveAnswers answer: NSStringFromSelector(_cmd)];
}
- (void)testOkUidvalidity1Line {
    
    const char *line = "* OK [UIDVALIDITY 1312094147] UIDs valid\r\n";
    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];
    
    [self parseDataBuffer: newData responseMethod: @"Uidvalidity:" saveAnswer: saveAnswers answer: NSStringFromSelector(_cmd)];
}
- (void)testOkUidnext1Line {
    
    const char *line = "* OK [UIDNEXT 12598] Predicted next UID\r\n";
    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];
    
    [self parseDataBuffer: newData responseMethod: @"Uidnext:" saveAnswer: saveAnswers answer: NSStringFromSelector(_cmd)];
}
- (void)testXList1LineNoLineFeed {
    
    const char *line = "* XLIST (\\HasNoChildren) \"/\" \"admin@moedae.com's Inbox/mz1.moedaworks.com\"\r";
    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];
    
    [parser addDataBuffer: newData];
    
    IMAPResponse* response = nil;
    IMAPParseResult result = [self.parser parseBuffer: &response];
        
    XCTAssertTrue(result == IMAPParseUnexpectedEnd, @"Parse result: %i", result);
}

- (void)testDoneOkFetchCompleted {
    
    const char *line = "a0003 OK Fetch completed.\r\n";
    NSMutableData *newData = [[NSMutableData alloc] initWithBytes: line length: strlen(line)];
    
    [self parseDataBuffer: newData responseMethod: @"commandDone:" saveAnswer: saveAnswers answer: NSStringFromSelector(_cmd)];
}

#pragma mark delegate response methods
-(void) responseBye: (id) response {
    
}
-(void) responseUnknown: (id) response {
    
}
-(void) responseFlags: (id) response {
}
-(void) responseXlist: (id) response {
    self.actionCalled = NSStringFromSelector(_cmd);
}
-(void) responseList: (id) response {
    [self responseXlist: response];
}
-(void) responseLsub: (id) response {}
-(void) responseSearch: (id) response {}
-(void) responseStatus: (id) response {}
-(void) responseExists: (id) response {
    
}
-(void) responseRecent: (id) response {
    
}

// Message responses
-(void) responseExpunge: (id) response {
    
}
-(void) responseFetch: (id) response {
    //IMAPResponseBuffer *passedParser = (IMAPResponseBuffer *)response;
    //MBTokenTree *tokens = passedParser.tokens;
    //DDLogVerbose(@"delegate method: %@ - parser tokens: %@", NSStringFromSelector(_cmd), tokens);
    self.actionCalled = NSStringFromSelector(_cmd);
}

// Resp-text-codes
-(void) responseCapability: (id) response {
//    IMAPResponseBuffer *passedParser = (IMAPResponseBuffer *)response;
//    MBTokenTree *tokens = passedParser.tokens;
//    DDLogVerbose(@"delegate method: %@ - parser tokens: %@", NSStringFromSelector(_cmd), tokens);
    self.actionCalled = NSStringFromSelector(_cmd);
}
-(void) responseAlert: (id) response {}
-(void) responseIgnore: (id) response {}
-(void) responseBadcharset: (id) response {}
-(void) responseParse: (id) response {}
-(void) responsePermanentflags: (id) response {}
-(void) responseReadOnly: (id) response {}
-(void) responseReadWrite: (id) response {}
-(void) responseTrycreate: (id) response {}

-(void) responseUidnext: (id) response {
//    IMAPResponseBuffer *passedParser = (IMAPResponseBuffer *)response;
//    MBTokenTree *tokens = passedParser.tokens;
//    DDLogVerbose(@"delegate method: %@ - parser tokens: %@", NSStringFromSelector(_cmd), tokens);
    self.actionCalled = NSStringFromSelector(_cmd);
}

-(void) responseUidvalidity: (id) response {
//    IMAPResponseBuffer *passedParser = (IMAPResponseBuffer *)response;
//    MBTokenTree *tokens = passedParser.tokens;
//    DDLogVerbose(@"delegate method: %@ - parser tokens: %@", NSStringFromSelector(_cmd), tokens);
    self.actionCalled = NSStringFromSelector(_cmd);
}

-(void) responseUnseen: (id) response {
//    IMAPResponseBuffer *passedParser = (IMAPResponseBuffer *)response;
//    MBTokenTree *tokens = passedParser.tokens;
//    DDLogVerbose(@"delegate method: %@ - parser tokens: %@", NSStringFromSelector(_cmd), tokens);
    self.actionCalled = NSStringFromSelector(_cmd);
}

-(void) commandDone: (id) response {
//    IMAPResponseBuffer *passedParser = (IMAPResponseBuffer *)response;
//    MBTokenTree *tokens = passedParser.tokens;
//    DDLogVerbose(@"delegate method: %@ - parser tokens: %@", NSStringFromSelector(_cmd), tokens);
    self.actionCalled = NSStringFromSelector(_cmd);
}

-(void) commandContinue: (id) response {
//    IMAPResponseBuffer *passedParser = (IMAPResponseBuffer *)response;
//    MBTokenTree *tokens = passedParser.tokens;
//    DDLogVerbose(@"delegate method: %@ - parser tokens: %@", NSStringFromSelector(_cmd), tokens);
    self.actionCalled = NSStringFromSelector(_cmd);
}

#pragma mark - IMAPClientStore Protocol

-(BOOL) setMailBoxReadOnly: (NSString *) fullPath {
    BOOL result = YES;
    
    self.actionCalled = @"setMailBoxReadOnly:";
    return result;
}
-(BOOL) setMailBoxReadWrite: (NSString *) fullPath {
    
    BOOL result = YES;
    
    self.actionCalled = @"setMailBoxReadWrite:";
    return result;
}
-(BOOL) setMailBoxFlags: (NSArray *) flagTokens onPath:     (NSString *) fullPath withSeparator: (NSString *) aSeparator {
    
    BOOL result = YES;
    
    self.actionCalled = @"setMailBoxFlags:";
    return result;
}

-(BOOL) setMailBox: (NSString *) fullPath       AvailableFlags:     (NSArray *) flagTokens {
    
    BOOL result = YES;
    
    self.actionCalled = @"AvailableFlags:";
    return result;
}
-(BOOL) setMailBox: (NSString *) fullPath       PermanentFlags:     (NSArray *) flagTokens {
    
    BOOL result = YES;
    
    self.actionCalled = @"PermanentFlags:";
    return result;
}
-(BOOL) setMailBox: (NSString *) fullPath       serverHighestmodseq: (NSNumber *) theCount {
    
    BOOL result = YES;
    
    self.actionCalled = @"serverHighestmodseq:";
    return result;
}
-(BOOL) setMailBox: (NSString *) fullPath       serverMessageCount: (NSNumber *) theCount {
    
    BOOL result = YES;
    
    self.actionCalled = @"serverMessageCount:";
    return result;
}
-(BOOL) setMailBox: (NSString *) fullPath       serverRecentCount:  (NSNumber *) theCount {
    
    BOOL result = YES;
    
    self.actionCalled = @"serverRecentCount:";
    return result;
}
-(BOOL) setMailBox: (NSString *) fullPath       Uidnext:            (NSNumber *) uidNext {
    
    BOOL result = YES;
    
    self.actionCalled = @"Uidnext:";
    return result;
}
-(BOOL) setMailBox: (NSString *) fullPath       Uidvalidity:        (NSNumber *) uidValidity {
    
    BOOL result = YES;
    
    self.actionCalled = @"Uidvalidity:";
    return result;
}
-(BOOL) setMailBox: (NSString *) fullPath       serverUnseen:       (NSNumber *) unseen {
    
    BOOL result = YES;
    self.actionCalled = @"serverUnseen:";
    return result;
}

-(BOOL) selectedMailBoxDeleteAllMessages:  (NSError**) error {
    
    BOOL result = YES;
    
    return result;
}


/*!
 All of the following message methods work on the messages in the selectedMBox.
 */
-(BOOL) setMessage: (NSNumber*) uid propertiesFromDictionary: (NSDictionary*) aDictionary {
    
    BOOL result = YES;
    
    self.actionCalled = @"setMessage:";
    return result;
}

@end
