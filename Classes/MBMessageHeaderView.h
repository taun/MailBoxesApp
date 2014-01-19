//
//  MBMessageHeaderView.h
//  MailBoxes
//
//  Created by Taun Chapman on 10/28/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MBMessage+IMAP.h"

@interface MBMessageHeaderView : NSView

@property (strong, nonatomic)          MBMessage*         message;

@property (weak) IBOutlet NSTextField *subject;
@property (weak) IBOutlet NSTextField *dateSent;
@property (weak) IBOutlet NSTextField *recipients;
@property (weak) IBOutlet NSTextField *sender;

@end
