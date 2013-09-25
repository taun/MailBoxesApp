//
//  MBSidebar+Accessors.h
//  MailBoxes
//
//  Created by Taun Chapman on 11/14/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import "MBSidebar.h"

#define MBSideBarEntityName @"MBSidebar"

#define MBGroupAccountsIdentifier @"accounts"
#define MBGroupSmartFoldersIdentifier @"smartfolders"
#define MBGroupFavoritesIdentifier @"favorites"
#define MBGroupListsIdentifier @"alists"

@class MBGroup;

/*!
 Accessors category add convenience accessors to MBSideBar.
 */
@interface MBSidebar (Accessors)

/*!
 Groups are added to the end of the childNodes NSOrderedSet.
 In other words, Groups are listed in the order in which they are added.
 
 @param identifier NSString
 @param aName NSString
 */
-(MBGroup*) addGroup: (NSString *)identifier name:(NSString *)aName;
  
- (MBGroup*) accountGroup; 
- (NSOrderedSet*) accounts; 

- (MBGroup*) smartFoldersGroup; 
- (NSOrderedSet*) smartFolders; 

- (MBGroup*) favoritesGroup; 
- (NSOrderedSet*) favorites; 

- (MBGroup*) listsGroup; 
- (NSOrderedSet*) lists; 
@end
