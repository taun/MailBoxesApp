//
//  MainSplitViewDelegate.h
//  MailBoxes
//
//  Created by Taun Chapman on 12/20/10.
//  Copyright 2010 MOEDAE LLC. All rights reserved.
//
// Explain why a separate MainSplitViewDelegate?
//

#import <Cocoa/Cocoa.h>
#import "MBGUIStateAutoSave.h"

extern NSString *const MBUPMainSplitWidth;
extern NSString *const MBUPMainSplitIsCollapsed;


@interface MainSplitViewDelegate : NSObject <NSSplitViewDelegate, MBGUIStateAutoSave>

@property(strong)     IBOutlet  NSView       *accountView;
@property(strong)     IBOutlet  NSView       *rightView;
@property(assign)             CGFloat       lastDividerPosition;
@property (weak)      IBOutlet NSButton     *collapseButton;

@property (strong) IBOutlet NSLayoutConstraint *leftSplitMinWidthConstraint;

- (IBAction) toggleAccountView: sender;

@end
