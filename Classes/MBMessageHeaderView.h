//
//  MBMessageHeaderView.h
//  MailBoxes
//
//  Created by Taun Chapman on 10/28/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <MoedaeMailPlugins/MoedaeMailPlugins.h>

@interface MBMessageHeaderView : MMPBaseMimeView


@property (weak) IBOutlet NSTextField *subject;
@property (weak) IBOutlet NSTextField *dateSent;
@property (weak) IBOutlet NSTextField *recipients;
@property (weak) IBOutlet NSTextField *sender;

@end
