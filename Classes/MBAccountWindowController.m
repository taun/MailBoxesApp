//
//  MBAccountWindowController.m
//  MailBoxes
//
//  Created by Taun Chapman on 12/8/10.
//  Copyright 2010 MOEDAE LLC. All rights reserved.
//

#import "MBAccountWindowController.h"
#import "MailBoxesAppDelegate.h"
#import "MBAccount+IMAP.h"
#import "MBUser+IMAP.h"
#import "MBSidebar+Accessors.h"
#import "MBTreeNode+IntersectsSetFix.h"

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@interface MBAccountWindowController ()


@end

@implementation MBAccountWindowController

@synthesize appWindow;
@synthesize localManagedContext;
@synthesize appManagedContext;
@synthesize appSelectedUserObjectController;

@synthesize theNewAccountObjectController;

@synthesize statusField;
@synthesize statusLight;
@synthesize pinger;

#pragma mark - 
#pragma mark Setup

- (void)windowWillLoad {
    DDLogVerbose(@"%@: %@\n", NSStringFromSelector(_cmd), [self.theNewAccountObjectController content]);
}

- (void)windowDidLoad {
    DDLogVerbose(@"%@: %@\n", NSStringFromSelector(_cmd), [self.theNewAccountObjectController content]);
}

- (NSManagedObjectContext *)appManagedContext {
    return [appSelectedUserObjectController managedObjectContext];
}

- (NSManagedObjectContext *)localManagedContext {
    if (localManagedContext == nil) {
        localManagedContext = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSMainQueueConcurrencyType];
        [localManagedContext setParentContext: [self appManagedContext]];
    }
    DDLogVerbose(@"Called %@ - %@", NSStringFromSelector(_cmd), localManagedContext);
    return localManagedContext;
}

-(id) init {
    if ((self = [super  initWithWindowNibName: @"MBModifyAccount"])) {        
    }    
 	return self;
}

- (void)awakeFromNib {
    _savedFirstResponder = [self.window firstResponder];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(documentWindowWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object: self.appWindow];
}

-(MBAccount*) currentAccount {
    return [self.theNewAccountObjectController content];
}

- (void) editAccountID:(NSManagedObjectID *)accountID {
    [self editViewForAccountID: accountID];
}

- (IBAction)add: sender { 
    [self editViewForAccountID: nil];
}

- (void)editViewForAccountID: (NSManagedObjectID*) accountID {

    NSManagedObjectContext* moc = self.localManagedContext;
    if (accountID == nil) {
        // need to add a new account
        [moc performBlockAndWait:^{
            [[self localManagedContext] reset];
 
            NSUndoManager *undoManager = [moc undoManager];
            [undoManager disableUndoRegistration];
            
            id newObject = [self.theNewAccountObjectController newObject];
            [self.theNewAccountObjectController addObject:newObject];
            
            [moc processPendingChanges];
            [undoManager enableUndoRegistration];
        }];
        
    } else {
        // editing an existing account
        MBAccount* account;
        //[self.localManagedContext performBlockAndWait:^{
            account = (MBAccount*) [moc objectWithID: accountID];
        //}];
        [self.theNewAccountObjectController setContent: account];
    }
    
    [self.window makeFirstResponder: _savedFirstResponder];
    
    // open the sheet to edit the new MBAccount
    DDLogVerbose(@"%@: %@\n", NSStringFromSelector(_cmd), self.theNewAccountObjectController);
    DDLogVerbose(@"\tContent:\n%@\n", [self.theNewAccountObjectController content]);
    [NSApp beginSheet: self.window
       modalForWindow: self.appWindow
        modalDelegate: self
       didEndSelector:@selector(newPortalObjectSheetDidEnd:returnCode:contextInfo:)
          contextInfo:NULL];
}

#pragma mark -
#pragma mark Clean up and terminate window

- (IBAction)complete:sender {
    __block NSError *error = nil;

    if (![self.theNewAccountObjectController commitEditing]) {
        DDLogVerbose(@"%@:%@ unable to commit editing before saving", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    }
    
    MBAccount *newAccount = [self.theNewAccountObjectController content];
    
    // get user id from app context
    NSManagedObjectID *userID = [[self.appSelectedUserObjectController content] objectID];
    
    
    // add to user.sidebar accounts set
    __block BOOL result;
    [self.localManagedContext performBlockAndWait:^{
        // get local context version
        MBUser *localUser = (MBUser *)[self.localManagedContext objectWithID: userID];
        newAccount.user = localUser;
        newAccount.imageName = MBAccountImageName;
        MBTreeNode* userAccountGroup = (MBTreeNode*)[localUser.sidebar accountGroup];
        [userAccountGroup addChildNodesObject: newAccount];
        result = [self.localManagedContext save: &error];
    }];
    
    if (!result) {
        [[NSApplication sharedApplication] presentError:error];
    } else {
        [NSApp endSheet: self.window returnCode:NSOKButton];
        
    } 
}

- (IBAction)cancelOperation:sender {
    [NSApp endSheet: self.window returnCode:NSCancelButton];
}

- (void)newPortalObjectSheetDidEnd:(NSWindow *)sheet
                        returnCode:(int)returnCode
                       contextInfo:(void  *)contextInfo {
    

    DDLogVerbose(@"%@: %@\n", NSStringFromSelector(_cmd), self.theNewAccountObjectController);
    DDLogVerbose(@"\tContent:\n%@\n", [self.theNewAccountObjectController content]);
    // Clean up before ending
    [self.theNewAccountObjectController setContent:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [self.localManagedContext performBlockAndWait:^{
        [[self localManagedContext] reset];
    }];
    
    [self.window orderOut:self];
}

- (void)documentWindowWillClose:(NSNotification *)note {
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //[self.window autorelease];
    //[self.theNewAccountObjectController autorelease];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender {
    return [self.localManagedContext undoManager];
}

- (IBAction)undo:sender {
    [self.localManagedContext performBlockAndWait:^{
        [[localManagedContext undoManager] undo];
    }];
}

- (IBAction)redo:sender {
    [self.localManagedContext performBlockAndWait:^{
        [[localManagedContext undoManager] redo];
    }];
}


#pragma mark - 
#pragma mark Connection Verification
/*
Create a Ping Instance on server host with delegate as self.
Need to go through a callback dance.
 
 */

- (void)updateStatus: (NSString *) status level: (uint) anError {
    NSString* currentFieldString = [self.statusField stringValue];
    [self.statusField setStringValue: [currentFieldString stringByAppendingFormat: @"\n>%@", status]];
	DDLogVerbose(@"%@", status);

    if(anError) [self.statusLight stopAnimation: self];

}
- (IBAction)testConnection: (id) sender {

    // 1) Test the network connection somehow.
    // 2) Test the connection to the server address. Can it be pinged?
    // 3) Try the actual mail connection and check for errors.
        
    [self.statusLight startAnimation: self];
    
    if( [self.theNewAccountObjectController commitEditing] == YES) {
        NSManagedObject *accountSettings = [self currentAccount];
        
        self.pinger = [Ping pingWithHostName:[accountSettings valueForKey:@"server"] ];
        self.pinger.delegate = self;
        [self.pinger start];
        NSString *status = [NSString localizedStringWithFormat:@"Testing connection to server %@", [accountSettings valueForKey:@"server"]];
        [self updateStatus:status level: 0];
    }
}

- (void) checkForAccount {
    // Check for the existance of the server mail account by logging in.
    
    NSManagedObject *accountSettings = [self currentAccount];

    [self updateStatus: [NSString localizedStringWithFormat:@"Logging in to server: %@, user: %@", 
                         [accountSettings valueForKey:@"server"],
                         [accountSettings valueForKey:@"username"]] level: 0];
    
//    CTCoreAccount	*testAccount = [[CTCoreAccount alloc] init];
//        
//    if (testAccount) {
//        uint connType;
//        if([[accountSettings valueForKey: @"useTLS"] boolValue] == YES) connType = CONNECTION_TYPE_TLS;
//        else connType = CONNECTION_TYPE_PLAIN;
//
//        @try {
//            [testAccount connectToServer: [accountSettings valueForKey:@"server"] 
//                                    port: [[accountSettings valueForKey:@"port"] intValue]
//                          connectionType: connType
//                                authType: IMAP_AUTH_TYPE_PLAIN 
//                                   login: [accountSettings valueForKey:@"username"] 
//                                password: [accountSettings valueForKey:@"password"]];
//            [self updateStatus: [NSString stringWithFormat:@"Login to %@ successfull", [accountSettings valueForKey:@"server"]] level: 0];
//        }
//        @catch(NSException *exception){
//            [self updateStatus: [NSString stringWithFormat:@"Connection Error %@", [exception reason]] level: 1] ;
//        }
//        @finally {
//            [testAccount disconnect];
//            [testAccount release];
//            testAccount = nil;
//        }
//    }
    [self.statusLight stopAnimation: self];
}

- (void)Ping:(Ping *)aPinger didStartWithAddress:(NSData *)address {
    // Called after the Ping has successfully started up.  After this callback, you 
    // can start sending pings via -sendPingWithData:
    [aPinger sendPingWithData: nil];    
}

- (void)Ping:(Ping *)apinger didFailWithError:(NSError *) error {
    // If this is called, the Ping object has failed.  By the time this callback is 
    // called, the object has stopped (that is, you don't need to call -stop yourself).

    NSManagedObject *accountSettings = [self currentAccount];
    NSString *status = [NSString localizedStringWithFormat:@"Failed ping to server %@. Error %@", [accountSettings valueForKey:@"server"], error];
    [self updateStatus:status level: 1];
}

// IMPORTANT: On the send side the packet does not include an IP header. 
// On the receive side, it does.  In that case, use +[Ping icmpInPacket:] 
// to find the ICMP header within the packet.

- (void)Ping:(Ping *)aPinger didSendPacket:(NSData *)packet {
    // Called whenever the Ping object has successfully sent a ping packet. 
}

- (void)Ping:(Ping *)aPinger didFailToSendPacket:(NSData *)packet error:(NSError *)error {
    // Called whenever the Ping object tries and fails to send a ping packet.
    [aPinger stop];
    
    NSManagedObject *accountSettings = [self currentAccount] ;
    NSString *status = [NSString localizedStringWithFormat:@"Failed ping to server %@. Error %@", [accountSettings valueForKey:@"server"], error];
    [self updateStatus:status level: 1];
}
    
- (void)Ping:(Ping *)aPinger didReceivePingResponsePacket:(NSData *)packet{
    // Called whenever the Ping object receives an ICMP packet that looks like 
    // a response to one of our pings (that is, has a valid ICMP checksum, has 
    // an identifier that matches our identifier, and has a sequence number in 
    // the range of sequence numbers that we've sent out).

    [aPinger stop];
    
    NSManagedObject *accountSettings = [self currentAccount] ;
    NSString *status = [NSString localizedStringWithFormat:@"Successful ping to server %@", [accountSettings valueForKey:@"server"]];
    [self updateStatus:status level: 0];
    [self checkForAccount];
}

- (void)Ping:(Ping *)aPinger didReceiveUnexpectedPacket:(NSData *)packet {
    // Called whenever the Ping object receives an ICMP packet that does not 
    // look like a response to one of our pings.
    [pinger stop];
    
    NSManagedObject *accountSettings = [self currentAccount] ;
    NSString *status = [NSString localizedStringWithFormat:@"Failed ping to server %@", [accountSettings valueForKey:@"server"]];
    [self updateStatus:status level: 0];
}

- (void)dealloc {
    [pinger setDelegate: nil];
}

@end
