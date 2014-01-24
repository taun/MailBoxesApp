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

@interface MBMessageViewController : NSCollectionViewItem <NSComboBoxDataSource, NSComboBoxDelegate>

@property (strong, nonatomic) IBOutlet NSObjectController *messageController;

#pragma Envelope Fields
@property (weak) IBOutlet NSTextField *subject;
@property (weak) IBOutlet NSTextField *dateSent;
@property (weak) IBOutlet NSTextField *recipients;
@property (weak) IBOutlet NSTextField *sender;

@property (weak) IBOutlet MBMessageHeaderView *messageHeader;
@property (weak) IBOutlet NSComboBox *recipientsBox;

@property (weak) IBOutlet NSView* messageBodyViewContainer;

#pragma Body

//@property (strong) NSView* messageBodyView;

- (IBAction)showMessageDebug:(id)sender;
- (IBAction)showPartsInLog:(id)sender;
//- (IBAction)refreshMessageDisplay:(id)sender;

@end
