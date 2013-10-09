//
//  MBSidebarViewController.m
//  MailBoxes
//
//  Created by Taun Chapman on 11/17/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import "MBSidebarViewController.h"
#import "MBSidebarTableCellView.h"
#import "MBUser+IMAP.h"
#import "MBSidebar+Accessors.h"
#import "MBGroup+Accessors.h"
#import "MBSmartFolder.h"
#import "MBFavorites.h"
#import "MBAddressList.h"
#import "MBAccount+IMAP.h"
#import "MBox+IMAP.h"
#import "MBAccountWindowController.h"

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

static const int ddLogLevel = LOG_LEVEL_INFO;

@implementation MBSidebarViewController
@synthesize menuSidebarMailBoxNode;
@synthesize menuSidebarFavoriteGroup;
@synthesize editAccountSheet;
@synthesize menuSidebarAccountNode;
@synthesize menuSidebarAccountGroup;
@synthesize delegate;
@synthesize userController;
@synthesize currentUser;
@synthesize view;
@synthesize draggedNodes;
@synthesize managedObjectContext;

- (void) awakeFromNib {
    [self.view setFloatsGroupRows: NO];
    //[self expandItem:nil expandChildren:YES];
    
    [self.view registerForDraggedTypes:@[@"MBSmartFolder", 
                                        @"MBAccount", 
                                        @"MBFavorites", 
                                        @"MBAddressList"]];
    
    [self.view setDraggingSourceOperationMask: NSDragOperationEvery forLocal:YES];
    
    [self.view setDraggingDestinationFeedbackStyle: NSTableViewDraggingDestinationFeedbackStyleSourceList]; 
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(managedObjectContextDidChange:)
                                                 name:NSManagedObjectContextObjectsDidChangeNotification
                                               object: self.managedObjectContext];
}

-(NSManagedObjectContext*) managedObjectContext {
    return [self.currentUser managedObjectContext];
}

- (void) managedObjectContextDidChange: (NSNotification *)notification {
    //    NSManagedObjectContext *context = [self managedObjectContext];
    NSSet *updatedObjects = [notification userInfo][NSUpdatedObjectsKey]; 
    NSSet *insertedObjects = [notification userInfo][NSInsertedObjectsKey]; 
    NSSet *deletedObjects = [notification userInfo][NSDeletedObjectsKey]; 
    
    BOOL sidebarReload = NO;
    
    for (id object in updatedObjects) {
        // called for any change to an object
        if ([object isKindOfClass: [MBTreeNode class]]) {
            sidebarReload = YES;
            break;
        }
    }
    
    if (!sidebarReload) {
        // called only when object is first created
        // means there is no parent or valid data
        for (id object in insertedObjects) {
            if ([object isKindOfClass: [MBTreeNode class]]) {
                sidebarReload = NO;
                // will reload when updated/saved
                break;
            }
        }
        if (!sidebarReload) {
            for (id object in deletedObjects) {
                if ([object isKindOfClass: [MBTreeNode class]]) {
                    sidebarReload = YES;
                    break;
                }
            }
        }
    }
    // for now let's just reload the outline view for any update
    // which is worse enumerating through every updated object to see if it will effect the sidebar
    // or updating the sidebar for every new message?
    if (sidebarReload) {
        // reload then expand inserted objects
        if ([NSThread isMainThread]) {
            [self reloadData];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self reloadData];
            });
        }
    }
}

-(NSMenu*) menuForNode:(MBTreeNode *)node {
    NSMenu* result = nil;
    if ([node isKindOfClass: [MBGroup class]]) {
        //
        if (node == [self.currentUser.sidebar accountGroup]) {
            result = self.menuSidebarAccountGroup;
            
        } else if (node == [self.currentUser.sidebar favoritesGroup]) {
            result = self.menuSidebarFavoriteGroup;
            
        } else if (node == [self.currentUser.sidebar smartFoldersGroup]) {
            result = self.menuSidebarAccountGroup;
            
        } else if (node == [self.currentUser.sidebar listsGroup]) {
            result = self.menuSidebarAccountGroup;
            
        }
        
    } else if ([node isKindOfClass: [MBAccount class]]) {
        result = self.menuSidebarAccountNode;
        
    } else if ([node isKindOfClass: [MBox class]]) {
        result = self.menuSidebarMailBoxNode;
        
    }
    return result;
}

-(id) _selectedItem {
    id item = nil;
    
    NSInteger clickedRow = [self.view clickedRow];
    if (clickedRow >= 0) {
        item = [self.view itemAtRow: clickedRow];
    } else {
        NSInteger selectedRow = [self.view selectedRow];
        if (selectedRow >= 0) {
            item = [self.view itemAtRow: selectedRow];
        }
    }
    return item;
}

-(BOOL) _isSelectionOfType:(Class)theClass {
    BOOL result = NO;
    
    id item = [self _selectedItem];
    
    if ([item isKindOfClass: theClass]) {
        result = YES;
    } 
    
    return result;
}

-(BOOL) isMBAccountSelected {
    return [self _isSelectionOfType: [MBAccount class]];
}

-(BOOL) isMBSmartFolderSelected {
    return [self _isSelectionOfType: [MBSmartFolder class]];
}

-(IBAction)addAccount:(id)sender {
    [self expandAccountGroup];
    [self.editAccountSheet add: self];
}

- (IBAction)editAccount:(id)sender {
    id item = [self _selectedItem];
    
    if ([item isKindOfClass: [MBAccount class]]) {
        MBAccount* account = (MBAccount*) item;
        [self.editAccountSheet editAccountID: [account objectID]];
    }
}

-(IBAction)addFavorite:(id)sender {
    //[self.editAccountSheet add: self];
}

- (IBAction)editFavorite:(id)sender {
//    id item = [self _selectedItem];
//    
//    if ([item isKindOfClass: [MBAccount class]]) {
//        MBAccount* account = (MBAccount*) item;
//        [self.editAccountSheet editAccountID: [account objectID]];
//    }
}

-(IBAction)addList:(id)sender {
    //[self.editAccountSheet add: self];
}

- (IBAction)editList:(id)sender {
    //    id item = [self _selectedItem];
    //    
    //    if ([item isKindOfClass: [MBAccount class]]) {
    //        MBAccount* account = (MBAccount*) item;
    //        [self.editAccountSheet editAccountID: [account objectID]];
    //    }
}

-(IBAction)addSmartFolder:(id)sender {
    //[self.editAccountSheet add: self];
}

- (IBAction)editSmartFolder:(id)sender {
    //    id item = [self _selectedItem];
    //    
    //    if ([item isKindOfClass: [MBAccount class]]) {
    //        MBAccount* account = (MBAccount*) item;
    //        [self.editAccountSheet editAccountID: [account objectID]];
    //    }
}

- (void) deleteItem:(id)item {
    MBTreeNode* node = (MBTreeNode*) item;
    [self.managedObjectContext deleteObject: node];
}

- (IBAction)deleteAccount:(id)sender {
    [self deleteItem: [self _selectedItem]];
}

- (IBAction)deleteFavorite:(id)sender {
    [self deleteItem: [self _selectedItem]];
}

- (IBAction)deleteSmartFolder:(id)sender {
    [self deleteItem: [self _selectedItem]];
}

- (IBAction)deleteList:(id)sender {
    [self deleteItem: [self _selectedItem]];
}

- (IBAction)exportSelectedAccountSettings:(id)sender {
    [self exportAccountSettingsFor: [self _selectedItem]];
}

- (IBAction)exportAllAccountsSettings:(id)sender {
}

- (IBAction)importAccountSettings:(id)sender {
    NSWindow* window = [[NSApp delegate] appWindow];
    
    // Create and configure the panel.
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:NO];
    [panel setAllowsMultipleSelection:YES];
    [panel setMessage:@"Import one or more accounts."];
    
    // Display the panel attached to the document's window.
    [panel beginSheetModalForWindow: window completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSArray* urls = [panel URLs];
            
            // Use the URLs to build a list of items to import.
            for (NSURL* url in urls) {
                [self importAccountSettingsFor: url];
            }
        }
        
    }];
}

- (void) exportAccountSettingsFor:(MBAccount*)account {
    NSString *error;
    NSString *rootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    
    NSString* fileName = [NSString stringWithFormat: @"%@.plist", account.name];
    
    NSString *plistPath = [rootPath stringByAppendingPathComponent: fileName];
    
//    NSDictionary *plistDict = [NSDictionary dictionaryWithObjects:
//                               [NSArray arrayWithObjects: personName, phoneNumbers, nil]
//                                                          forKeys:[NSArray arrayWithObjects: @"Name", @"Phones", nil]];
//    NSData *plistData = [NSPropertyListSerialization dataFromPropertyList:plistDict
//                                                                   format:NSPropertyListXMLFormat_v1_0
//                                                         errorDescription:&error];
//    if(plistData) {
//        [plistData writeToFile:plistPath atomically:YES];
//    }
//    else {
//        DDLogError(@"%@", error);
//    }
    BOOL result = [NSKeyedArchiver archiveRootObject: account  toFile: plistPath];
    DDLogVerbose(@"%@ result: %i", NSStringFromSelector(_cmd), result);
}

- (void) importAccountSettingsFor: (NSURL*) accountFile {
    NSError *error;
    NSData* data = [NSData dataWithContentsOfURL: accountFile options: NSDataReadingUncached error: &error];
    if (data) {
        MBAccount* importedAccount = [NSKeyedUnarchiver unarchiveObjectWithData: data];
        importedAccount.imageName = MBAccountImageName;
        [importedAccount addParentNodesObject: [self.currentUser.sidebar accountGroup]];
        importedAccount.user = self.currentUser;
        DDLogVerbose(@"Importing url: %@, rootObject: %@", accountFile, importedAccount);
    } else {
        // there was an error
        // display error?
    }    
}


-(MBUser*) currentUser {
    return (MBUser*)[self.userController content];
}

-(void) reloadData {
    [self.view reloadData];
}

-(void) expandAccountGroup {
    NSInteger row = [self.view rowForItem: self.currentUser.sidebar.accountGroup];
    [self.view expandItem: self.currentUser.sidebar.accountGroup expandChildren: NO];
    DDLogVerbose(@"%@ row: %i", NSStringFromSelector(_cmd), row);
}

#pragma mark - Menu Delegate
- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem {
    
    SEL theAction = [anItem action];
    
    if (theAction == @selector(editAccount:)) {
        if (![self isMBAccountSelected]) {
            return NO;
        }
    } else if (theAction == @selector(editSmartFolder:)) {
        if (![self isMBSmartFolderSelected]) {
            return NO;
        }
    }

    return YES;
}

#pragma mark - Outline Data Source

- (NSInteger) outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    NSInteger children;
    if (item == nil) {
        children = [[self.currentUser.sidebar childNodes] count];
    } else {
        children = [[item  childNodes] count];
    }
    return  children;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    id result;
    if (item == nil) {
        // wants root item
        result = [self.currentUser.sidebar childNodes][index];
    } else {
        result = [item childNodes][index];
    }
    return result;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    BOOL expand;
    MBTreeNode* node = (MBTreeNode*)item;
    
    if ([outlineView parentForItem:item] == nil) {
        expand = YES;
    } else {
        NSNumber* isLeaf = [node isLeaf];
        expand = ![isLeaf boolValue];
    }
    return expand;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item {
    // As an example, hide the "outline disclosure button" for FAVORITES. This hides the "Show/Hide" button and disables the tracking area for that row.
    BOOL expand;
    
    if ([item isKindOfClass: [MBGroup class]]) {
        MBGroup* group = (MBGroup*)item;
        expand = [[group isExpandable] boolValue];
    } else {
        //default
        expand = YES;
    }
    return expand;
}

- (id)outlineView:(NSOutlineView *)outlineView 
persistentObjectForItem:(id)item {
    NSManagedObjectID *objectID = [item objectID];
    if ([objectID isTemporaryID])
    {
        if (![[item managedObjectContext] save:NULL])
        {
            return nil;
        }
        objectID = [item objectID];
    }
    return [[objectID URIRepresentation] absoluteString];
}

- (id)outlineView:(NSOutlineView *)outlineView 
itemForPersistentObject:(id)object {
    id result = nil;
    
    // This should probably be the delegate managedObjectContext
    // rather than embedding the currentUser?
    if (self.currentUser != nil) {
        NSManagedObjectContext* moc = self.managedObjectContext;
        NSPersistentStoreCoordinator* psc = [moc persistentStoreCoordinator];
        NSURL* objectURL = [NSURL URLWithString: object];
        NSManagedObjectID* objectID = [psc managedObjectIDForURIRepresentation: objectURL];
        if (objectID != nil) {
            NSManagedObject* managedObject = [moc objectWithID: objectID];
            result = managedObject;
        }
    }         
     return result;
}

#pragma mark - ***Outline Delegate Protocol***

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
    return [item isKindOfClass: [MBGroup class]];
}

- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView 
                 rowViewForItem:(id)item {
//    LPTableRowView *view = [[LPTableRowView alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)];
//    return [view autorelease];
    return nil;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView 
     viewForTableColumn:(NSTableColumn *)tableColumn 
                   item:(id)item {
    
    MBSidebarTableCellView* result;
    
    if (tableColumn == nil){
        result = [outlineView makeViewWithIdentifier:@"HeaderCell" owner:self];
        // Uppercase the string value, but don't set anything else. NSOutlineView automatically applies attributes as necessary
        NSString *value = [item name];
        [result.textField setStringValue:value];
        //        [result.textField.cell setMenu: self.menuSidebarGroup];
    } else {
        result = (MBSidebarTableCellView*) [outlineView makeViewWithIdentifier:@"MainCell" owner:self];
        NSString *value = [item name];
        [result.textField setStringValue:value];
        
        NSString* imageName = [item imageName];
        if (imageName) {
            NSString* imageNamePath = [[NSBundle mainBundle]
                                       pathForResource: imageName 
                                       ofType:@"tiff"
                                       inDirectory: @"Icons"];
            
            NSImage* tempImage = [[NSImage alloc] initWithContentsOfFile:imageNamePath];
            [result.imageView setImage: tempImage];
        } else {
            [result.imageView setImage: nil];
        }
        BOOL hideUnreadIndicator = YES;
        // Setup the unread indicator to show in some cases. Layout is done in SidebarTableCellView's viewWillDraw
        if ([item isKindOfClass: [MBox class]]) {
            MBox* mbox = (MBox*)item;
            
            NSNumber* theCount = [mbox serverUnseen];
            if (theCount != nil && [theCount intValue] > 0) {
                // First row in the index
                hideUnreadIndicator = NO;
                [result.button setTitle: [theCount stringValue]];
                [result.button sizeToFit];
                // Make it appear as a normal label and not a button
                [[result.button cell] setHighlightsBy:0];
            }
        }
        [result.button setHidden:hideUnreadIndicator];
    }
    return result;
}
/*
 Relay selection change to AppDelegate
 AppDelegate needs to update any portals which are dependent on the sidebar selection
   such as MBViewPortalSelection
 */
- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    MBTreeNode* selectedNode;
    if ([self.view selectedRow] != -1) {
        selectedNode = [self.view itemAtRow:[self.view selectedRow]];
        if ([self.view parentForItem: selectedNode] != nil) {
            // Only change things for non-root items (root items can be selected, but are ignored)
            //[self _setContentViewToName:item];
            [self.delegate nodeSelectionDidChange: selectedNode];
        }
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView willShowContextMenu:(id)item {
    
    DDLogVerbose(@"OutlineView %@", outlineView);
    return YES;
}

- (void)menuNeedsUpdate:(NSMenu *)menu {
    MBTreeNode* item = nil;
    NSInteger clickedRow = [self.view clickedRow];
    item = [self.view itemAtRow:clickedRow];
	
    [menu removeAllItems];
    
    NSMenu* newMenu = [self menuForNode: item];
    
    NSArray* newMenuItems = [newMenu itemArray];
    for (NSMenuItem* mItem in newMenuItems) {
        [menu addItem: [mItem copy]];
    }
}

#pragma mark - Outline Drag & Drop

/* Dragging Source Support - Required for multi-image dragging. Implement this method to allow the table to be an 
 NSDraggingSource that supports multiple item dragging. Return a custom object that implements NSPasteboardWriting 
 (or simply use NSPasteboardItem). If this method is implemented, then outlineView:writeItems:toPasteboard: will not be called.
 */
//- (id <NSPasteboardWriting>)outlineView:(NSOutlineView *)outlineView 
//                pasteboardWriterForItem:(id)item {
//    
//}

/* Dragging Source Support - Optional for single-image dragging. This method is called after it has been determined 
 that a drag should begin, but before the drag has been started.  To refuse the drag, return NO.  To start a drag, 
 return YES and place the drag data onto the pasteboard (data, owner, etc...).  The drag image and other drag 
 related information will be set up and provided by the outline view once this call returns with YES.  The items array 
 is the list of items that will be participating in the drag.
 */
- (BOOL)outlineView:(NSOutlineView *)outlineView 
         writeItems:(NSArray *)items 
       toPasteboard:(NSPasteboard *)pasteboard {
    
    BOOL result = NO;
    self.draggedNodes = items;
    
    if ([[items lastObject] isKindOfClass: [MBSmartFolder class]]) {
        
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject: items];
//        [pasteboard declareTypes:[NSArray arrayWithObject: @"MBSmartFolder"] owner:self];
        
//        NSData* data = [NSData data];
        [pasteboard setData: data forType:@"MBSmartFolder"];
        
        result = YES;
    } else if ([[items lastObject] isKindOfClass: [MBAccount class]]) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject: items];
        [pasteboard setData: data forType:@"MBAccount"];
        result = YES;
    } else if ([[items lastObject] isKindOfClass: [MBFavorites class]]) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject: items];
        [pasteboard setData: data forType:@"MBFavorites"];
        result = YES;
    } else if ([[items lastObject] isKindOfClass: [MBAddressList class]]) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject: items];
        [pasteboard setData: data forType:@"MBAddressList"];
        result = YES;
    }
    DDLogVerbose(@"allow drag: %@\n\tPasteboard items: %@", (result?@"YES":@"NO"), items);
    
    return result;
}

/* Dragging Source Support - Optional. Implement this method know when the dragging session is about to begin and 
 to potentially modify the dragging session. 'draggedItems' is an array of items that we dragged, excluding items 
 that were not dragged due to outlineView:pasteboardWriterForItem: returning nil. This array will directly match 
 the pasteboard writer array used to begin the dragging session with [NSView beginDraggingSessionWithItems:event:source]. 
 Hence, the order is deterministic, and can be used in -outlineView:acceptDrop:item:childIndex: when enumerating the 
 NSDraggingInfo's pasteboard classes. 
 */
- (void)outlineView:(NSOutlineView *)outlineView 
    draggingSession:(NSDraggingSession *)session 
   willBeginAtPoint:(NSPoint)screenPoint 
           forItems:(NSArray *)draggedItems {
    
    self.draggedNodes = [draggedItems copy];
    
    if ([draggedItems count]==1) {
        
        MBTreeNode* node = (MBTreeNode*)[draggedItems lastObject];
        MBGroup* parent = (MBGroup*)[[node parentNodes] lastObject];
        NSInteger index = [[parent childNodes] indexOfObject: node];
        NSIndexSet* indexes = [NSIndexSet indexSetWithIndex: index];
        
        DDLogVerbose(@"%@ - indexes:%@", NSStringFromSelector(_cmd), indexes);
        //[self.outlineView removeItemsAtIndexes: indexes inParent: parent withAnimation:NSTableViewAnimationEffectGap];
    }
    
    
    DDLogVerbose(@"begin dragging: %@ \n", draggedItems);
}

/* Dragging Source Support - Optional. Implement this method know when the dragging session has ended. This 
 delegate method can be used to know when the dragging source operation ended at a specific location, such as 
 the trash (by checking for an operation of NSDragOperationDelete).
 */
- (void)outlineView:(NSOutlineView *)outlineView 
    draggingSession:(NSDraggingSession *)session 
       endedAtPoint:(NSPoint)screenPoint 
          operation:(NSDragOperation)operation {
    
    if (operation == NSDragOperationDelete) {
        // moved to trash so delete
        for (id item in self.draggedNodes) {
            DDLogVerbose(@"Deleting Dragged item: %@ \n", item);
            [self.managedObjectContext deleteObject: item];
        }
    }
    DDLogVerbose(@"end drag operation: %i", operation);
}

/* Dragging Destination Support - Required for multi-image dragging. Implement this method to allow the table to 
 update dragging items as they are dragged over the view. Typically this will involve calling 
 [draggingInfo enumerateDraggingItemsWithOptions:forView:classes:searchOptions:usingBlock:] and setting the 
 draggingItem's imageComponentsProvider to a proper image based on the content. For View Based TableViews, one 
 can use NSTableCellView's -draggingImageComponents and -draggingImageFrame.
 */
//- (void)outlineView:(NSOutlineView *)outlineView updateDraggingItemsForDrag:(id <NSDraggingInfo>)draggingInfo {
//    
//}

/* Dragging Destination Support - This method is used by NSOutlineView to determine a valid drop target. 
 Based on the mouse position, the outline view will suggest a proposed child 'index' for the drop to happen 
 as a child of 'item'. This method must return a value that indicates which NSDragOperation the data source 
 will perform. The data source may "re-target" a drop, if desired, by calling setDropItem:dropChildIndex: and 
 returning something other than NSDragOperationNone. One may choose to re-target for various reasons (eg. for 
 better visual feedback when inserting into a sorted position). On Leopard linked applications, this method 
 is called only when the drag position changes or the dragOperation changes (ie: a modifier key is pressed). 
 Prior to Leopard, it would be called constantly in a timer, regardless of attribute changes.
 */
- (NSDragOperation)outlineView:(NSOutlineView *)outlineView 
                  validateDrop:(id <NSDraggingInfo>)info 
                  proposedItem:(id)item 
            proposedChildIndex:(NSInteger)index {
    
    NSDragOperation op = NSDragOperationNone;
    
    if ([info draggingSource] == self.view) {
        // local drag and drop
        id draggedItem = [self.draggedNodes lastObject];
        if ([item isKindOfClass: [MBGroup class]] && [[item childNodes] containsObject: draggedItem]) {
            // only allow dragging within common children
            
            info.animatesToDestination = YES;
            
            MBGroup* group = (MBGroup*)item;
            
            NSInteger currentPosition = [[group childNodes] indexOfObject: draggedItem];
            
            if (index == currentPosition || (index == currentPosition+1)) {
                // same position do nothing
                op = NSDragOperationNone;
            } else if (index == -1) {
                // drop into begining of group or end?
                // end
                if (currentPosition+1 != [[group childNodes] count]) {
                    // already at the end
                    op = NSDragOperationMove;
                }
                
            } else {
                op = NSDragOperationMove;
            }
            
            //[self.outlineView insertItemsAtIndexes: indexes inParent: parent withAnimation:NSTableViewAnimationEffectGap];
            
            //        id draggedItem = [self.draggedNodes lastObject];
            //        
            //        MBGroup* group = (MBGroup*)item;
            //        
            //        NSInteger currentPosition = [[group children] indexOfObject: draggedItem];
            //
            //        [self.outlineView moveItemAtIndex: currentPosition inParent: item toIndex: index inParent: item];
        }
        
    }
    
    DDLogVerbose(@"validateDrop proposedItem: %@, index: %ld, op: %ld\n", item, index, op);
    return op;
}

/* Dragging Destination Support - This method is called when the mouse is released over an outline view that 
 previously decided to allow a drop via the validateDrop method. The data source should incorporate the data 
 from the dragging pasteboard at this time. 'index' is the location to insert the data as a child of 'item', 
 and are the values previously set in the validateDrop: method.
 */
- (BOOL)outlineView:(NSOutlineView *)outlineView 
         acceptDrop:(id <NSDraggingInfo>)info 
               item:(id)item 
         childIndex:(NSInteger)index {
    
    id draggedItem = [self.draggedNodes lastObject];
    
    MBGroup* group = (MBGroup*)item;
    
    NSInteger currentPosition = [[group childNodes] indexOfObject: draggedItem];
    
    NSMutableOrderedSet* children = [[group childNodes] mutableCopy];
    
    [children removeObjectAtIndex: currentPosition];
    if (index >= 0 && index < currentPosition) {
        // removing object wont change new index position
        [children insertObject: draggedItem atIndex: index];
        group.childNodes = children;
        
    } else if (--index > currentPosition || index < 0) {
        // removing object will decrease desired index position by 1
        
        if (index >= [children count] || index < 0) {
            [children addObject: draggedItem];
            group.childNodes = children;
            index = [group.childNodes count]-1;
            
        } else {
            [children insertObject: draggedItem atIndex: index];
            group.childNodes = children;
            
        }
    } 
    
    self.draggedNodes = nil;
    
    [self.view moveItemAtIndex: currentPosition inParent: item toIndex: index inParent: item];
    
    DDLogVerbose(@"acceptDrop index: %ld\n", index);
    return YES;
}


@end
