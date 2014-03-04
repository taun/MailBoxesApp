//
//  MBMessagesSplitViewDelegate.m
//  MailBoxes
//
//  Created by Taun Chapman on 03/03/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBMessagesSplitViewDelegate.h"

NSString *const MBUPMessagesSplitIsVertical = @"messagesSplitViewIsVertical";

@implementation MBMessagesSplitViewDelegate


- (void)awakeFromNib {
    NSUserDefaults  *sud = [NSUserDefaults standardUserDefaults];
    
    
    if([sud boolForKey: MBUPMessagesSplitIsVertical]){
        [self.messagesSplitView setVertical: YES];
    }
    else {
        [self.messagesSplitView setVertical: NO];
    }
    
    return;
}

-(void) saveState {
    NSUserDefaults  *sud = [NSUserDefaults standardUserDefaults];
    [sud setBool: self.messagesSplitView.isVertical forKey: MBUPMessagesSplitIsVertical];
}

-(IBAction) toggleMessagesVerticalView:(id)sender {
    
    [self.messagesSplitView setVertical: ![self.messagesSplitView isVertical]];
    
    [self.messagesSplitView adjustSubviews];
}

#pragma mark - NSSplitViewDelegate 

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {
    return NO;
}

@end
