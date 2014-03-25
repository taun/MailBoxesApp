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
@class MMPMessageViewOptions;
@class SimpleRFC822Address;


/*
 Message body content flow.
 
 At the initial account synchronization, only the message headers and structure are downloaded. This is to speed up the sync.
 
 When the user clicks on a message, the body needs to be fetched and updated in the store.
 
 Clicking a message in a portal creates a MBMessageViewController with the message as representedObject.
 
 If the message body is not cached, MBMessageViewController asks the singleton accountsCoordinator to loadFullMessageID:forAccountID:
 The fetch is on a background thread so the data needs to be monitored for changes by the MBBodyStructureInlineView.
 
 
 */


@interface MBMessageViewController : NSCollectionViewItem <NSPopoverDelegate>


@property (nonatomic,strong) MMPMessageViewOptions          *options;

@property (strong) IBOutlet NSPopover *partsPopover;
@property (strong) IBOutlet NSPopover *addressPopover;
@property (strong) IBOutlet NSTreeController *popoverAddressesArrayController;
@property (strong) IBOutlet NSTreeController *addressesBccArrayController;
@property (strong) IBOutlet NSTreeController *addressesCcArrayController;
@property (strong) IBOutlet NSTreeController *addressesToArrayController;

@property (weak) IBOutlet MBMessageHeaderView *messageHeader;

@property (weak) IBOutlet MBBodyStructureInlineView* messageBodyViewContainer;

@property (strong,nonatomic) SimpleRFC822Address* cachedAddressesTo;
@property (strong,nonatomic) SimpleRFC822Address* cachedAddressesBcc;
@property (strong,nonatomic) SimpleRFC822Address* cachedAddressesCc;
@property (strong,nonatomic,readonly) NSArray*    emailSortDescriptors;

#pragma Body
-(void) reloadMessage;
//@property (strong) NSView* messageBodyView;

- (IBAction)showPartsPopover:(NSButton *)sender;
- (IBAction)showRecipientAddressPopover:(id)sender;
- (IBAction)showBccAddressPopover:(id)sender;
- (IBAction)showCcAddressPopover:(id)sender;

- (IBAction)showMessageDebug:(id)sender;
- (IBAction)showPartsInLog:(id)sender;
//- (IBAction)refreshMessageDisplay:(id)sender;
- (IBAction)showMessageAsPlainText:(id)sender;
- (IBAction)showMessageAsRichText:(id)sender;
- (IBAction)showConstraints:(id)sender;

@end
