//
//  MBCollectionViewItem.h
//  MailBoxes
//
//  Created by Taun Chapman on 05/10/11.
//  Copyright 2011 MOEDAE LLC. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>


/*!
 @header
 
 more later
 
 */


/*!
 @class MBCollectionViewItem
 
 @abstract more later
 
 @discussion more later
 
 */
@interface MBPortalViewController : NSCollectionViewItem <NSTableViewDelegate> 

@property (strong,readonly)     NSArray         *collectionItemSortDescriptors;
@property (strong,readonly)     NSPredicate     *compoundPredicate;
@property (strong)              NSPredicate     *searchPredicate;

@property (strong) IBOutlet     NSArrayController       *messagesController;
@property (strong)   IBOutlet     NSTableView             *tableView;


- (IBAction)growTableRows:(id)sender;
- (IBAction)shrinkTableRows:(id)sender;

@end
