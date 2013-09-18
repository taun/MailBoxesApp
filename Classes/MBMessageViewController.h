//
//  MBMessageViewController.h
//  MailBoxes
//
//  Created by Taun Chapman on 10/21/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MBMessage;

@interface MBMessageViewController : NSViewController <NSOutlineViewDelegate, NSOutlineViewDataSource>

@property (strong, nonatomic) IBOutlet NSObjectController *messageController;
@property (strong, nonatomic)          MBMessage*         message;

#pragma Envelope Fields
@property (weak) IBOutlet NSTextField *subject;
@property (weak) IBOutlet NSTextField *dateSent;
@property (weak) IBOutlet NSTextField *recipients;
@property (weak) IBOutlet NSTextField *sender;

@property (weak) IBOutlet id messageBodyViewContainer;

#pragma Body
@property (weak) IBOutlet NSOutlineView *outlineView;

- (IBAction)showMessageDebug:(id)sender;
- (IBAction)showPartsInLog:(id)sender;
- (IBAction)refreshMessageDisplay:(id)sender;

@end
