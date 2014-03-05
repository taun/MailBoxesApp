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

@property (strong,nonatomic,readonly)     NSArray         *messagesArray;
@property (strong,nonatomic,readonly)     NSArray         *collectionItemSortDescriptors;
@property (strong,nonatomic,readonly)     NSPredicate     *compoundPredicate;
@property (strong,nonatomic)              NSPredicate     *searchPredicate;
@property (strong,nonatomic,readonly)     NSSet           *selectedMessages;

@property (strong) IBOutlet     NSArrayController       *messagesController;
@property (strong) IBOutlet     NSTableView             *tableView;

-(void) contentUpdated;

- (IBAction)changePortalColor:(id)sender;

- (IBAction)growTableRows:(id)sender;
- (IBAction)shrinkTableRows:(id)sender;
- (IBAction)reloadMessageBody:(id)sender;
- (IBAction)logAddresses:(id)sender;

@end
