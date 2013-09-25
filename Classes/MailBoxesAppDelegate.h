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
 The standard AppDelegate class.
 
 */
@interface MailBoxesAppDelegate : NSObject <NSApplicationDelegate, MBSidebarViewDelegate>

/// @name Main window views and controls
/*! Standard AppDelegate window */
@property(strong)           IBOutlet NSWindow                 *appWindow;
@property(strong)           IBOutlet MainSplitViewDelegate    *mainSplitViewDelegate;
@property(strong)           IBOutlet NSView                   *inPaneMessageView;
@property(strong)           IBOutlet NSObjectController       *selectedUserController;
@property(strong)                    MBMessageViewController  *messageViewController;
@property (weak)            IBOutlet MBSidebarViewController  *sidebarViewController;

@property(nonatomic,readonly,strong) NSArray                  *portalsACSortDescriptors;
@property(nonatomic,readonly,strong) NSArray                  *accountsACSortDescriptors;

/// @name Configuration windows
@property(strong)           IBOutlet NSWindow                 *preferencesWindow;
@property(strong)           IBOutlet NSProgressIndicator      *accountSyncProgress;
@property(strong)           IBOutlet NSButton                 *accountSyncButton;
@property(strong)           IBOutlet NSButton                 *accountSyncCancelButton;
/*!
 The portalsArrayController content set comes from self.currentUser.portals
 
 @see MBUser
 @see MBViewPortal
 */
@property(strong)           IBOutlet NSArrayController        *portalsArrayController;
/*! The collectionView content comes from self.portalsArrayController
 
 Each NSCollectionView item is represented by an instance of MBVPortal.xib.
 
 Each MBVPortal.xib is controlled by a MBPortalViewController.
 
 @see MBViewPortal
 @see MBCollectionView
 @see MBPortalViewController
 */
@property(strong)           IBOutlet MBCollectionView         *collectionView;
@property(strong)           IBOutlet NSSplitView              *messagesSplitView;

/// @name Model root
/*!
 It all starts with the MBUser, currentUser. The definition of the current user is persisted in the OS User preferences.
 If there is no currentUser, a default current user is created via the private method createDefaultUser.
 
 The MBUser stores the account information, array of portals...
 
 @see MBUser
 */
@property(strong)                    MBUser                   *currentUser;

/// @name accessors for Core Data
@property(nonatomic,readonly,strong) NSPersistentStoreCoordinator    *persistentStoreCoordinator;
@property(nonatomic,readonly,strong) NSManagedObjectModel            *managedObjectModel;
@property(nonatomic,readonly,strong) NSManagedObjectContext          *managedObjectContext;
@property(nonatomic,readonly,strong) NSManagedObjectContext          *nibManagedObjectContext;

/// @name Networking
/*! The MBAccountsCoordinator.
 
 Manages all of the account information and network communication for the current MBUser.
 
 @see MBAccountsCoordinator
 */
@property (strong)           MBAccountsCoordinator          *accountsCoordinator;
@property (strong)           NSOperationQueue               *syncQueue;

/// @name Control Actions
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

/// @name  Debug Actions
- (IBAction)resetMailStore:(id)sender;
- (IBAction)resetCoreData:(id)sender;
- (IBAction)resetPortals:(id)sender;


-(void) displayContextSaveError: (NSError*) theError;

@end
