//
//  MBPPEWindowController.m
//  MailBoxes
//
//  Created by Taun Chapman on 3/3/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//

/*
 ToDo: 
  Get the predicate string from current portal selection
    how to trigger action on portal selection?
  Convert the portal predicate string into a new NSPredicate
  Assign the portal nspredicate to the NSPredicateEditor
 
 Add a view for live predicate query results
    shaped like a portal. Insert the portal nib view?
 
 */
#import "MailBoxesAppDelegate.h"
#import "MBPPEWindowController.h"
#import "MBPortal+IMAP.h"
#import "MBUser+IMAP.h"

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

static const int ddLogLevel = LOG_LEVEL_WARN;

#define DEFAULT_PREDICATE @"(name = 'inbox')" 

@implementation MBPPEWindowController

@synthesize appWindow;

@synthesize query;
@synthesize predicateEditor;
@synthesize previousRowCount;

@synthesize portalsArrayController;
@synthesize theNewPortalObjectController;
//@synthesize predicate;

@synthesize localManagedContext;
@synthesize appManagedContext;
@synthesize appSelectedUserObjectController;

#pragma mark - 
#pragma mark Setup

- (NSManagedObjectContext *)appManagedContext {
    return [portalsArrayController managedObjectContext];
}

- (NSManagedObjectContext *)localManagedContext {
    if (localManagedContext == nil) {
        localManagedContext = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSMainQueueConcurrencyType];
        [localManagedContext setParentContext: [self appManagedContext]];
    }
    return localManagedContext;
}

- (id)initWithNib: (NSString *) theNib {
    if ((self = [super  initWithWindowNibName: theNib])) {        
    }    
 	return self;
}

- (IBAction)add:sender {
    if (self.window == nil) {
        NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
        NSNib *nib = [[NSNib alloc] initWithNibNamed:@"MBPortalPredicateEditor" bundle:myBundle];
        
        NSArray* topLevelObjextsArray;
        BOOL success = [nib instantiateNibWithOwner:self topLevelObjects: &topLevelObjextsArray];
        // Check the topLevelObjects to see if theyy are strong outlets
        if (success != YES) {
            // should present error
            return;
        }
    }
    NSUndoManager *undoManager = [[self localManagedContext] undoManager];
    [undoManager disableUndoRegistration];
    
    id newObject = [self.theNewPortalObjectController newObject];
    [self.theNewPortalObjectController addObject: newObject];
    
    [self.localManagedContext performBlockAndWait:^{
        [localManagedContext processPendingChanges];
    }];

    [undoManager enableUndoRegistration];
    
//    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter]; 
//    [nc addObserver:self
//           selector:@selector(mergeChanges:) 
//               name:NSManagedObjectContextDidSaveNotification
//             object:self.localManagedContext];
    
    [NSApp beginSheet: self.window
       modalForWindow: self.appWindow
        modalDelegate: self
       didEndSelector:@selector(newPortalObjectSheetDidEnd:returnCode:contextInfo:)
          contextInfo:NULL];
}

//- (void)mergeChanges:(NSNotification *)notification
//{	
//	// Merge changes into the main context on the main thread
//	[self.appManagedContext performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:)	
//                                  withObject:notification
//                               waitUntilDone:YES];	
//    MailBoxesAppDelegate *mbapp = [[NSApplication sharedApplication] delegate];
//    [mbapp performSelectorOnMainThread: @selector(saveAction:) withObject: nil waitUntilDone: YES];
//}

#pragma mark -
#pragma mark Clean up and terminate window

- (IBAction)complete:sender {
    [NSApp endSheet: self.window returnCode:NSOKButton];
}

- (IBAction)cancelOperation:sender {
    [NSApp endSheet: self.window returnCode:NSCancelButton];
}

- (void)newPortalObjectSheetDidEnd:(NSWindow *)sheet
                        returnCode:(int)returnCode
                       contextInfo:(void  *)contextInfo {
    
    __block NSError *error = nil;
    
    //NSManagedObject *sheetObject = [self.newPortalObjectController content];
    
    if (returnCode == NSOKButton) {
        MBPortal *newPortal = [self.theNewPortalObjectController content];
        // get user id from app context
        NSManagedObjectID *userID = [[[self appSelectedUserObjectController] content] objectID];
        // get local context version
        
        __block MBUser *localUser;
        
        [self.localManagedContext performBlockAndWait:^{
            localUser = (MBUser *)[localManagedContext objectWithID: userID];
        }];
        
        newPortal.parentNode = localUser;
        
        if (![self.theNewPortalObjectController commitEditing]) {
            DDLogVerbose(@"%@:%@ unable to commit editing before saving", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
        }
        
        __block BOOL result;
        
        [self.localManagedContext performBlockAndWait:^{
            result = [self.localManagedContext save: &error];
        }];

        if (!result) {
            [[NSApplication sharedApplication] presentError:error];
        } else {
            [NSApp endSheet: self.window returnCode:NSOKButton];
        } 
    }
    
    // Clean up before ending
    [self.theNewPortalObjectController setContent:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver: self];

    [self.localManagedContext performBlockAndWait:^{
        [[self localManagedContext] reset];
    }];
    
    [self.window orderOut:self];
}

- (void)awakeFromNib {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(documentWindowWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object: self.appWindow];

    // Start of adding live query for portal preview
    //self.query = [[NSMetadataQuery alloc] init];
    //[self.query setDelegate: self];
    
    // self.predicate = [[NSPredicate predicateWithFormat:DEFAULT_PREDICATE] retain];
    if ([self.predicateEditor numberOfRows] == 0) [self.predicateEditor addRow:self];
    //DDLogVerbose(@"MBPPE awakeFromNib %@", self.predicateEditor);
}


- (void)documentWindowWillClose:(NSNotification *)note {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //[self.window autorelease];
    //[self.newPortalObjectController autorelease];
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
/*
- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    DDLogVerbose(@"MBPPE windowDidLoad %@", predicateEditor);
    
}
*/


#pragma mark -
#pragma mark Predicate editor code
- (IBAction)predicateEditorChanged:(id)sender {
    // Need to display the predicate result
    // Then save the predicate as a string to the portal property
    if ([self.predicateEditor numberOfRows] == 0) [self.predicateEditor addRow:self];
    DDLogVerbose(@"MBPPE predicateEditorChanged predicate string: %@", [[self.predicateEditor objectValue] predicateFormat]);
    
}


@end
