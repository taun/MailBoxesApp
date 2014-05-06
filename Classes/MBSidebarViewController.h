//
//  MBSidebarViewController.h
//  MailBoxes
//
//  Created by Taun Chapman on 11/17/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MBTreeNode;
@class MBUser;
@class MBAccount;
@class MBAccountWindowController;

@protocol MBSidebarViewDelegate

-(void)nodeSelectionDidChange: (MBTreeNode*) node;

@optional

@end

/*!
 Controller for the accounts, folders and favorites sidebar listing.
 */
@interface MBSidebarViewController : NSObject <NSMenuDelegate, NSOutlineViewDelegate, NSOutlineViewDataSource>

/*!
 Delegate is for passing on information regarding the current selection.
 */
@property (weak) IBOutlet id<MBSidebarViewDelegate> delegate;

@property (unsafe_unretained) IBOutlet NSObjectController       *selectedUserController;
@property (readonly, weak)             MBUser                   *currentUser;
@property (readonly, weak)             NSManagedObjectContext   *managedObjectContext;
@property (weak) IBOutlet NSOutlineView            *view;
@property (strong)                     NSArray                  *draggedNodes;
@property (weak) IBOutlet NSMenu                   *menuSidebarAccountNode;
@property (weak) IBOutlet NSMenu                   *menuSidebarAccountGroup;
@property (weak) IBOutlet NSMenu                   *menuSidebarMailBoxNode;
@property (weak) IBOutlet NSMenu                   *menuSidebarFavoriteGroup;
@property (weak) IBOutlet MBAccountWindowController *editAccountSheet;

-(NSMenu*) menuForNode: (MBTreeNode*) node;

- (IBAction)addAccount:(id)sender;
- (IBAction)addFavorite:(id)sender;
- (IBAction)addSmartFolder:(id)sender;
- (IBAction)addList:(id)sender;

- (IBAction)editAccount:(id)sender;
- (IBAction)editFavorite:(id)sender;
- (IBAction)editSmartFolder:(id)sender;
- (IBAction)editList:(id)sender;

- (IBAction)deleteAccount:(id)sender;
- (IBAction)deleteFavorite:(id)sender;
- (IBAction)deleteSmartFolder:(id)sender;
- (IBAction)deleteList:(id)sender;
- (void) deleteItem: (id) item;

- (IBAction)exportSelectedAccountSettings:(id)sender;
- (IBAction)exportAllAccountsSettings:(id)sender;
- (IBAction)importAccountSettings:(id)sender;
- (void) exportAccountSettingsFor: (MBAccount*) account;
- (void) importAccountSettingsFor: (NSURL*) accountFile;

-(void) reloadData;
-(void) managedObjectContextDidChange: (NSNotification *)notification;

-(void) expandAccountGroup;
-(void) expandFavoritesGroup;
-(void) expandSmartFolderGroup;
-(void) expandListGroup;

-(BOOL) isMBAccountSelected;
-(BOOL) isMBSmartFolderSelected;
-(BOOL) _isSelectionOfType: (Class) theClass;
-(id) _selectedItem;

@end
