
//
//  MailBoxesAppDelegate.m
//  MailBoxes
//
//  Created by Taun Chapman on 11/10/10.
//  Copyright (c) 2010 MOEDAE LLC. All rights reserved.
//

#import "MailBoxesAppDelegate.h"
#import "MainSplitViewDelegate.h"
#import "MBAccountWindowController.h"
#import "MBPPEWindowController.h"
#import "MBTreeNode.h"
#import "MBGroup.h"
#import "MBSidebar+Accessors.h"
#import "MBSmartFolder.h"
#import "MBFavorites.h"
#import "MBUser+IMAP.h"
#import "MBAccount+IMAP.h"
#import "MBox+IMAP.h"
#import "MBMessage+IMAP.h"
#import "MBPortal+Accessors.h"
#import "MBCriteria.h"
#import "MBPortalView.h"
#import "MBPortalsCollectionView.h"
#import "MBMessageViewController.h"
#import "MBViewPortalSelection.h"
#import "MBAddressList.h"
#import "MBSidebarViewController.h"
#import "MBAccountsCoordinator.h"
#import "MBPortalViewController.h"
#import "MBMessageHeaderView.h"
#import "MBMessageView.h"
#import "NSView+MBConstraintsDebug.h"

#import "MBSimpleRFC822AddressToStringTransformer.h"
#import "MBSimpleRFC822AddressSetToStringTransformer.h"
#import "MBMIME2047ValueTransformer.h"
#import "MBMIMECharsetTransformer.h"
#import "MBMIMEQuotedPrintableTranformer.h"

#import <FScript/FScript.h>
#import <QuartzCore/QuartzCore.h>

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;


#define MBCoreDataErrorDomain @"com.moedae.MailBoxes.CoreData"
#define MBStoreDataName @"MailBoxes.storedata"
#define MBGroupEntityName @"MBGroup"
#define MBAccountEntityName @"MBAccount"
#define MBSmartFolderEntityName @"MBSmartFolder"
#define MBoxEntityName @"MBox"
#define MBFavoriteEntityName @"MBFavorites"
#define MBListsEntityName @"MBAddressList"

@interface MailBoxesAppDelegate()
@property(nonatomic,readwrite,strong) NSArray                         *accountsACSortDescriptors;
@property(nonatomic,readwrite,strong) NSArray                         *portalsACSortDescriptors;

@property(nonatomic,readwrite,strong) NSPersistentStoreCoordinator    *persistentStoreCoordinator;
@property(nonatomic,readwrite,strong) NSManagedObjectModel            *managedObjectModel;
@property(nonatomic,readwrite,strong) NSManagedObjectContext          *managedObjectContext;
@property(nonatomic,readwrite,strong) NSManagedObjectContext          *nibManagedObjectContext;

//name Startup
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
- (void)loadCurrentUser;
- (void)createDefaultUser;
- (void)createDefaultSidebarContent; 
- (void)createDefaultPortal;
- (BOOL)isThereAUser;

//name State
- (IBAction)showPreferences: (id) sender;
- (void)saveCurrentUserPreference;


//name Mail Core
/*!
 Create a CTCoreAccount for each MBAccount - iterate user.childNodes and pass to 
 Create MBox for each CTCoreAccount folder and add as MBAccount childNodes relationship 

 @result an IBAction
 */
- (IBAction)loadAllAccountFolders: (id) sender;

//Core Data Boilerplate
//- (NSString *)applicationSupportDirectory;
//- (NSManagedObjectModel *)managedObjectModel;
//- (NSPersistentStoreCoordinator *) persistentStoreCoordinator;
//- (NSManagedObjectContext *) managedObjectContext;
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window;

//name Clean up and terminate
- (void)dealloc;
- (IBAction) saveAction:(id)sender;
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;
- (void)applicationWillTerminate:(NSNotification *)notification;
@end

@implementation MailBoxesAppDelegate

#pragma mark - Startup
///@name Startup
+ (void)initialize {
    NSDictionary *defaults = 
    @{@"messageQuanta": @20,
        @"accountSplitWidth": @275.0f,
        @"isAccountCollapsed": @"NO",
        @"selectedUser": @"",
        @"NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints": @"YES"};
    
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];

    AccountEditingEndedKey = @"AccountEditingEnded";
    PortalEditingEndedKey = @"PortalEditingEnded";
    
    [NSValueTransformer setValueTransformer: [MBSimpleRFC822AddressToStringTransformer new]
                                    forName: VTAddressToString];
    
    [NSValueTransformer setValueTransformer: [MBSimpleRFC822AddressSetToStringTransformer new]
                                    forName: VTAddressesToString];
    
    [NSValueTransformer setValueTransformer: [MBMIME2047ValueTransformer new]
                                    forName: VTRFC2047EncodedToString];

    [NSValueTransformer setValueTransformer: [MBMIMEQuotedPrintableTranformer new]
                                    forName: VTQuotedPrintableToString];

}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqual:@"isFinished"]) {
        DDLogVerbose(@"%@: isFinished=%@ observer triggered.", NSStringFromClass([self class]), [object valueForKeyPath:keyPath]);
        if (self.accountsCoordinator.isFinished) {
            [self setSyncStatus: NO];
        }
    }else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)awakeFromNib {
    
//    NSClipView* clipView = [self.inPaneMessageView contentView];
//    [clipView setTranslatesAutoresizingMaskIntoConstraints: NO];

    return;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    //Taun move to object?
	if(self)
	{
        FScriptMenuItem *fsm = [[FScriptMenuItem alloc] init];
        [[NSApp mainMenu] addItem: fsm];
        
        [DDLog addLogger:[DDASLLogger sharedInstance]];
        [DDLog addLogger:[DDTTYLogger sharedInstance]];
        
        if(![self isThereAUser])
            [self createDefaultUser];
        
        // It is important this happens after all the nib loading and binding.
        [self.sidebarViewController.view setAutosaveExpandedItems: YES];
        [self.sidebarViewController reloadData];
        
        _syncQueue = nil;
        
        self.accountsCoordinator = [[MBAccountsCoordinator alloc] initWithMBUser: self.currentUser];
        [self.accountsCoordinator addObserver:self
                                   forKeyPath:@"isFinished"
                                      options:NSKeyValueObservingOptionNew
                                      context:NULL];
        
        //        [[NSNotificationCenter defaultCenter] addObserver:self
        //                                                 selector:@selector(managedObjectContextDidChange:)
        //                                                     name:NSManagedObjectContextObjectsDidChangeNotification
        //                                                   object: self.managedObjectContext];
    }
}

- (NSArray*) accountsACSortDescriptors {
    if(_accountsACSortDescriptors == nil) {
        NSSortDescriptor* sort = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector: @selector(localizedCaseInsensitiveCompare:)];
        _accountsACSortDescriptors = @[sort];
    }
    return _accountsACSortDescriptors;
}

- (NSArray*) portalsACSortDescriptors {
    if(_portalsACSortDescriptors == nil) {
        NSSortDescriptor* sort = [[NSSortDescriptor alloc] initWithKey:@"position" ascending:YES selector: @selector(compare:)];
        _portalsACSortDescriptors = @[sort];
    }
    return _portalsACSortDescriptors;
}
- (void)createDefaultUser {
    __block MBUser *newUser = nil;
    __block NSError *errorSavingUser = nil;
    
    [self.managedObjectContext performBlockAndWait:^{
        newUser = [NSEntityDescription insertNewObjectForEntityForName:@"MBUser" inManagedObjectContext: _managedObjectContext];
        [newUser setValue: @"default" forKey: @"firstName"];
        
        self.currentUser = newUser;
        
        [self createDefaultSidebarContent];
        [self createDefaultPortal];
        
        if ([_managedObjectContext save: &errorSavingUser] == NO) {
            [_managedObjectContext deleteObject:newUser];
            DDLogVerbose(@"An error occurred while inserting and saving an initial User: %@",
                         [errorSavingUser localizedDescription]);
            self.currentUser = nil;
            newUser = nil;
        } else {
            DDLogVerbose(@"No initial User was found, inserted and saved an initial User: %@", newUser);
        }
    }];
    
    if (self.currentUser != nil) {
        [self saveCurrentUserPreference];
    }
}
- (void)createDefaultSidebarContent {
    MBSidebar* sidebar = [NSEntityDescription insertNewObjectForEntityForName:MBSideBarEntityName
                                                       inManagedObjectContext:self.managedObjectContext];
    sidebar.name = @"Root";
    sidebar.identifier = @"root";
    self.currentUser.sidebar = sidebar;
    
    [sidebar addGroup: MBGroupAccountsIdentifier name:@"Accounts"];
    
    MBGroup* favorites = [sidebar addGroup: MBGroupFavoritesIdentifier name:@"Favorites"];
    favorites.isOwner = @NO;
    favorites.isExpandable = @YES;
    
    [sidebar addGroup: MBGroupSmartFoldersIdentifier name:@"SmartFolders"];
    
    
    MBGroup* lists = [sidebar addGroup: MBGroupListsIdentifier name:@"Lists"];
    lists.isOwner = @NO;
    lists.isExpandable = @YES;
}
- (void)createDefaultPortal {
    MBViewPortalSelection* selectionPortal = [NSEntityDescription insertNewObjectForEntityForName: @"MBViewPortalSelection"
                                                                           inManagedObjectContext:self.managedObjectContext];
    selectionPortal.name = @"Default";
    [self.currentUser addPortalsObject: selectionPortal];
}
- (BOOL)isThereAUser {
    BOOL status = NO;
    
    NSURL *moURI;
    NSManagedObjectID *suid;
    
    __block NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MBUser"];
    
    __block NSError *error = nil;
    __block NSArray *fetchedObjects;
    
    
    [self.managedObjectContext performBlockAndWait:^{
        fetchedObjects = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    }];
    
    
    if ( (fetchedObjects == nil) || ([fetchedObjects count] <= 0) ) {
        status = NO;
    }
    else {
        moURI = [[NSUserDefaults standardUserDefaults] URLForKey: @"selectedUser"];
        suid = [self.persistentStoreCoordinator managedObjectIDForURIRepresentation: moURI];
        if ( suid == nil ) {
            //no currently stored default user so take the first from the store
            self.currentUser = fetchedObjects[0];
        }
        else {
            __block MBUser *cUser = nil;
            
            [self.managedObjectContext performBlockAndWait:^{
                cUser = (MBUser *)[_managedObjectContext objectWithID: suid];
            }];
            
            self.currentUser = cUser;
        }
        status = YES;
    }
    return status;
}
- (void)loadCurrentUser {
    __block NSError *errorLoading = nil;
    __block BOOL savedOK = NO;
    __block MBUser* theCurrentUser;
    
    NSURL *moURI = [[NSUserDefaults standardUserDefaults] URLForKey: @"selectedUser"];
    NSManagedObjectID *suid = [[self persistentStoreCoordinator] managedObjectIDForURIRepresentation: moURI];
    if ( suid != nil ) {
        [self.managedObjectContext performBlockAndWait:^{
            theCurrentUser = (MBUser *)[_managedObjectContext existingObjectWithID: suid error: &errorLoading];
        }];
        self.currentUser = theCurrentUser;
    }
}


/*
 Monitor NSCollectionView indexes to update Message Window
 */
-(void) setSyncStatus:(BOOL) syncOn {
    // Swap Cancel and Sync buttons
    [self.accountSyncButton setHidden: syncOn];    
    [self.accountSyncCancelButton setHidden: !syncOn];
    //[self.accountSyncProgress setHidden: !syncOn];
    
    if(syncOn){
        [self.accountSyncProgress startAnimation: self];
        //[self.accountSyncProgress display];
    } else {
        [self.accountSyncProgress stopAnimation: self];
    }    
}

#pragma mark - State
///@name State
- (void)saveCurrentUserPreference {
    NSURL *moURI = [[self.currentUser objectID] URIRepresentation];
    [[NSUserDefaults standardUserDefaults] setURL: moURI forKey:@"selectedUser"];
}

- (IBAction)showPreferences: (id) sender {
    // below should be a WindowController not a window. Create a preferences window controller?
    [self.preferencesWindow makeKeyAndOrderFront: self];
}

- (IBAction)exportSelectedPortalSettings:(id)sender {
}

- (IBAction)exportAllPortalSettings:(id)sender {
}

- (IBAction)importPortalSettings:(id)sender {
}

-(IBAction)testIMAPClient:(id)sender {
    [self.accountsCoordinator testIMAPClientComm];
}

#pragma mark - View Management

-(IBAction) toggleMessagesVerticalView:(id)sender {
    
    [self.messagesSplitView setVertical: ![self.messagesSplitView isVertical]];
    
    [self.messagesSplitView adjustSubviews];
    
    //[self.messagesSplitView setNeedsDisplay: YES];
 }


#pragma message "TODO:Now"

#pragma mark - NSCollectionViewDelegate Protocol
/* Perhaps should be moved to the CollectionViewController class ? */
/* Invoked when the mouse is released over a collection view that previously allowed a drop. */
- (BOOL)collectionView:(NSCollectionView *)collectionView acceptDrop:(id < NSDraggingInfo >)draggingInfo index:(NSInteger)index dropOperation:(NSCollectionViewDropOperation)dropOperation {
    return NO;
}
/* Returns whether the collection view can attempt to initiate a drag for the given event and items. */
- (BOOL)collectionView:(NSCollectionView *)collectionView canDragItemsAtIndexes:(NSIndexSet *)indexes withEvent:(NSEvent *)event {
    return NO;
}
/* Sent to the delegate to allow creation of a custom image to represent collection view items during a drag operation. */
- (NSImage *)collectionView:(NSCollectionView *)collectionView draggingImageForItemsAtIndexes:(NSIndexSet *)indexes withEvent:(NSEvent *)event offset:(NSPointPointer)dragImageOffset {
    return nil;
}
/* Invoked to determine a valid drop target. */
- (NSDragOperation)collectionView:(NSCollectionView *)collectionView validateDrop:(id < NSDraggingInfo >)draggingInfo proposedIndex:(NSInteger *)proposedDropIndex dropOperation:(NSCollectionViewDropOperation *)proposedDropOperation {
    return nil;
}
/* Invoked after it has been determined that a drag should begin, but before the drag has been started. */
- (BOOL)collectionView:(NSCollectionView *)collectionView writeItemsAtIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard {
    return NO;
}
#pragma mark - MBSidebarViewDelegate Protocol

/*
 Update portals which depend on node selection
 MBViewPortalSelection instances
 Should only be one.
 */
-(void)nodeSelectionDidChange:(MBTreeNode *)node {
    id portals = [self.portalsArrayController arrangedObjects];
    if ([node isKindOfClass:[MBox class]]) {
        for (id portal in portals) {
            if ([portal isKindOfClass:[MBViewPortalSelection class]]) {
                DDLogCVerbose(@"Change portal: %@ selection to node: %@", portal, node);
                [(MBViewPortalSelection*)portal setName: [node name]];
                [(MBViewPortalSelection*)portal setMessageArraySource: node];
            }
        }
    } else if ([node isKindOfClass:[MBSmartFolder class]]) {
        
    } else if ([node isKindOfClass:[MBFavorites class]]) {
        
    }
}

#pragma mark - IMAPSync
//name IMAPSync
/*!
    ToDo
 
        Change this to setup IMAPSync process
    
        Need separate MOC, NSOperation, merge changes, observer
 
    @param sender standard control action form
    @result an IBAction
 */
- (IBAction)loadAllAccountFolders: (id) sender {
    if(self.syncQueue == nil){
        self.syncQueue = [[NSOperationQueue alloc] init];
    }
    if (self.syncQueue) {
        //work
        
        [self.accountsCoordinator refreshAll];
        
        if (!self.accountsCoordinator.isFinished) {
            // Only set the sync status once. Not for each account
            [self setSyncStatus: YES];
        }
    } else {
        //handle error
    }
    
//    NSUInteger portalCount = [self.collectionView content ].count;
//    for (NSUInteger portalIndex=0; portalIndex < portalCount; portalIndex++) {
//        MBPortalViewController* pvController = (MBPortalViewController*)[self.collectionView itemAtIndex: portalIndex];
//        [pvController.messagesController rearrangeObjects];
//    }
}

- (IBAction)cancelLoadAllAccountFolders:(id)sender {
    NSAssert(self.accountsCoordinator, @"No account coordinator defined.");
    [self.accountsCoordinator closeAll];
    [self setSyncStatus: NO];
}

#pragma mark - Core Data Boilerplate
//name Core Data Boilerplate
/**
 Returns the directory the application uses to store the Core Data store file. This code uses a directory named "TestCoreData" in the user's Library directory.
 New
 */
- (NSURL *)applicationFilesDirectory {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *libraryURL = [[fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
    return [libraryURL URLByAppendingPathComponent:@"MailBoxes"];
}

/**
 Creates if necessary and returns the managed object model for the application.
 */
- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel==nil) {
        //NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"MailBoxesDataModel" withExtension:@"momd"];
        //managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
        _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles: nil];
    }
	
    return _managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator==nil) {
        NSManagedObjectModel *mom = self.managedObjectModel;
        if (!mom) {
            DDLogVerbose(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
            return nil;
        }
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
        NSError *error = nil;
        
        NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
        
        if (!properties) {
            BOOL ok = NO;
            if ([error code] == NSFileReadNoSuchFileError) {
                ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
            }
            if (!ok) {
                [[NSApplication sharedApplication] presentError:error];
                return nil;
            }
        }
        else {
            if ([properties[NSURLIsDirectoryKey] boolValue] != YES) {
                // Customize and localize this error.
                NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]]; 
                
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
                error = [NSError errorWithDomain: MBCoreDataErrorDomain code:101 userInfo:dict];
                
                [[NSApplication sharedApplication] presentError:error];
                return nil;
            }
        }
        
        NSURL *storeURL = [applicationFilesDirectory URLByAppendingPathComponent: MBStoreDataName];
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
            [[NSApplication sharedApplication] presentError:error];
            _persistentStoreCoordinator = nil;
            return nil;
        }
    }
        
    return _persistentStoreCoordinator;
}

/**
 Returns the managed object context for the application (which is already
 bound to the persistent store coordinator for the application.) 
 */
- (NSManagedObjectContext *)managedObjectContext {
    if (_managedObjectContext==nil) {
        NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
        if (!coordinator) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
            [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
            NSError *error = [NSError errorWithDomain: MBCoreDataErrorDomain code:9999 userInfo:dict];
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    
    return _managedObjectContext;
}

- (NSManagedObjectContext *)nibManagedObjectContext {
    return self.managedObjectContext;
}

/*!
 Some discussion here

 @param window NSWindow
 @returns Returns the NSUndoManager for the application.  In this case, the manager
 returned is that of the managed object context for the application.
 */
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [self.managedObjectContext undoManager];
}

- (IBAction)undo:sender {
    [self.managedObjectContext performBlockAndWait:^{
        [[self.managedObjectContext undoManager] undo];
    }];
}
- (IBAction)redo:sender {
    [self.managedObjectContext performBlockAndWait:^{
        [[self.managedObjectContext undoManager] redo];
    }];
}

#pragma mark - Clean up and terminate
//name Clean up and terminate
/*!
Performs the save action for the application, which is to send the save:
message to the application's managed object context.  Any encountered errors
are presented to the user.

@param sender standard IBAction form
@returns returns an IBAction
 */
- (IBAction) saveAction:(id)sender {
    __block NSError *error = nil;
    
    __block BOOL result;
    
    [self.managedObjectContext performBlockAndWait:^{
        result = [self.managedObjectContext commitEditing];
    }];

    if (!result) {
        DDLogVerbose(@"%@:%@ unable to commit editing before saving", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    }

    [self.managedObjectContext performBlockAndWait:^{
        result = [self.managedObjectContext save:&error];
    }];
    
    if (!result) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication*)sender
{
    if (!self.managedObjectContext) return NSTerminateNow;
    
    __block BOOL result;
    
    [self.managedObjectContext performBlockAndWait:^{
        result = [self.managedObjectContext commitEditing];
    }];
    
    if (!result) {
        DDLogVerbose(@"%@:%@ unable to commit editing to terminate", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![self.managedObjectContext hasChanges]) return NSTerminateNow;
    
    __block NSError *error = nil;
    [self.managedObjectContext performBlockAndWait:^{
        result = [self.managedObjectContext save:&error];
    }];
    if (!result) {
        // TODO: add more detailed error reporting here. Need to show CoreData validation errors
        // and give a chance to go back and correct them. Ideally show validation errors earlier.
        
        DDLogVerbose(@"%@:%@ unable to save managedObjectContext", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
        DDLogVerbose(@"managedObjectContext Error: %@:%@", [error localizedDescription], [error localizedFailureReason]);
        BOOL shouldCancel = [sender presentError:error];
        if (shouldCancel) return NSTerminateCancel;
        
        NSString *question = NSLocalizedString(@"Could not save changes while quitting.  Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
        
        NSInteger answer = [alert runModal];
        if (answer == NSAlertAlternateReturn) return NSTerminateCancel;
        
    }
    
    return NSTerminateNow;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    NSUserDefaults *sud;
    sud = [NSUserDefaults standardUserDefaults];
    [self.mainSplitViewDelegate saveViewSettingsOn: sud];
    [self saveCurrentUserPreference];
    [sud synchronize];
}

- (void)dealloc {  
    [self.accountsCoordinator removeObserver: self forKeyPath: @"isFinished"];
}

- (IBAction)resetMailStore:(id)sender {
}

- (IBAction)resetCoreData:(id)sender {
    NSURL *storeURL = [[self applicationFilesDirectory] URLByAppendingPathComponent: MBStoreDataName];
    [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
}

- (IBAction)resetPortals:(id)sender {
}

- (IBAction)visualizeConstraints:(id)sender {
    [self.appWindow visualizeConstraints: [self.self.messageViewController.view mbAllConstraints]];
    
//    CGRect tvFrame = self.messageViewController.messageBodyView.frame;
//    CGSize tcSize = [[(NSTextView*)self.messageViewController.messageBodyView textContainer] containerSize];
//    NSLog(@"TextView Frame: %@; TextContainer Size: %@", NSStringFromRect(tvFrame), NSStringFromSize(tcSize));
    
//    CGRect bodyContainerFrame = self.messageViewController.messageBodyViewContainer.frame;
//    CGRect messageFrame = self.messageViewController.messageBodyViewContainer.superview.frame;
//    NSLog(@"Body Frame: %@; Message Frame: %@", NSStringFromRect(bodyContainerFrame), NSStringFromRect(messageFrame));
}
@end
