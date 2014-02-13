//
//  MBMessageViewController.h
//  MailBoxes
//
//  Created by Taun Chapman on 10/21/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MBMessage;
@class MBMessageHeaderView;
@class MBBodyStructureInlineView;


/*
 Message body content flow.
 
 At the initial account synchronization, only the message headers and structure are downloaded. This is to speed up the sync.
 
 When the user clicks on a message, the body needs to be fetched and updated in the store.
 
 Clicking a message in a portal creates a MBMessageViewController with the message as representedObject.
 
 If the message body is not cached, MBMessageViewController asks the singleton accountsCoordinator to loadFullMessageID:forAccountID:
 The fetch is on a background thread so the data needs to be monitored for changes by the MBBodyStructureInlineView.
 
 
 */


@interface MBMessageViewController : NSCollectionViewItem <NSComboBoxDataSource, NSComboBoxDelegate, NSPopoverDelegate>

@property (strong, nonatomic) IBOutlet NSObjectController *messageController;

@property (strong) IBOutlet NSPopover *partsPopover;

#pragma Envelope Fields
@property (weak) IBOutlet NSTextField *subject;
@property (weak) IBOutlet NSTextField *dateSent;
@property (weak) IBOutlet NSTextField *recipients;
@property (weak) IBOutlet NSTextField *sender;

@property (weak) IBOutlet MBMessageHeaderView *messageHeader;
@property (weak) IBOutlet NSComboBox *recipientsBox;

@property (weak) IBOutlet MBBodyStructureInlineView* messageBodyViewContainer;

#pragma Body

//@property (strong) NSView* messageBodyView;
- (IBAction)showPartsPopover:(NSButton *)sender;

- (IBAction)showMessageDebug:(id)sender;
- (IBAction)showPartsInLog:(id)sender;
//- (IBAction)refreshMessageDisplay:(id)sender;

@end
