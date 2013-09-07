//
//  MailBoxesAppDelegate.h
//  MailBoxes
//
//  Created by Taun Chapman on 11/10/10.
//  Copyright (c) 2010 MOEDAE LLC. All rights reserved.
//
// Consider adding custom core data store which uses imap as a store
// Would allow core data to query store and retrieve remote email 
// as if it were just standard model data.

#import <Cocoa/Cocoa.h>
#import "MBSidebarViewController.h"

@class MBAccountWindowController;
@class MBPPEWindowController;
@class MainSplitViewDelegate;
@class MBUser;
@class MBCollectionView;
@class MBAccountsCoordinator;
@class MBMessage;
@class MBMessageViewController;

NSString *AccountEditingEndedKey;
NSString *PortalEditingEndedKey;

/*!
 @header
 
 main application
 
 */

/*!
 created by the IB template
 
 */
@interface MailBoxesAppDelegate : NSObject <NSApplicationDelegate, MBSidebarViewDelegate>

// Main window views and controls
@property(strong)           IBOutlet NSWindow                 *appWindow;
@property(strong)           IBOutlet MainSplitViewDelegate    *mainSplitViewDelegate;
@property(strong)           IBOutlet NSView                   *inPaneMessageView;
@property(strong)           IBOutlet NSObjectController       *selectedUserController;
@property(strong)                    MBMessageViewController  *messageViewController;
@property (weak)            IBOutlet MBSidebarViewController  *sidebarViewController;

@property(nonatomic,readonly,strong) NSArray                  *portalsACSortDescriptors;
@property(nonatomic,readonly,strong) NSArray                  *accountsACSortDescriptors;

// Configuration windows
@property(strong)           IBOutlet NSWindow                 *preferencesWindow;
@property(strong)           IBOutlet NSProgressIndicator      *accountSyncProgress;
@property(strong)           IBOutlet NSButton                 *accountSyncButton;
@property(strong)           IBOutlet NSButton                 *accountSyncCancelButton;
@property(strong)           IBOutlet NSArrayController        *portalsArrayController;
@property(strong)           IBOutlet MBCollectionView         *collectionView;
@property(strong)           IBOutlet NSSplitView              *messagesSplitView;

// Model root
@property(strong)                    MBUser                   *currentUser;

// accessors for Core Data
@property(nonatomic,readonly,strong) NSPersistentStoreCoordinator    *persistentStoreCoordinator;
@property(nonatomic,readonly,strong) NSManagedObjectModel            *managedObjectModel;
@property(nonatomic,readonly,strong) NSManagedObjectContext          *managedObjectContext;
@property(nonatomic,readonly,strong) NSManagedObjectContext          *nibManagedObjectContext;

// Networking
@property (strong)           MBAccountsCoordinator          *accountsCoordinator;
@property (strong)           NSOperationQueue               *syncQueue;


- (IBAction)undo:sender;
- (IBAction)redo:sender;
- (IBAction)showPreferences: (id) sender;
- (IBAction)loadAllAccountFolders: (id) sender;
- (IBAction)saveAction: (id) sender;
- (IBAction)cancelLoadAllAccountFolders:(id)sender;
- (IBAction)toggleMessagesVerticalView:(id)sender;
- (IBAction)testIMAPClient:(id)sender;
- (void) showSelectedMessage: (MBMessage *) selectedMessage; 

- (IBAction)exportSelectedPortalSettings:(id)sender;
- (IBAction)exportAllPortalSettings:(id)sender;
- (IBAction)importPortalSettings:(id)sender;

#pragma mark - Debug Actions
- (IBAction)resetMailStore:(id)sender;
- (IBAction)resetCoreData:(id)sender;
- (IBAction)resetPortals:(id)sender;


-(void) displayContextSaveError: (NSError*) theError;

@end
