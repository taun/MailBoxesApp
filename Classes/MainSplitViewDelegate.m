//
//  MainSplitViewDelegate.m
//  MailBoxes
//
//  Created by Taun Chapman on 12/20/10.
//  Copyright 2010 MOEDAE LLC. All rights reserved.
//

#import "MainSplitViewDelegate.h"

@interface MainSplitViewDelegate () 
- (BOOL) isAccountCollapsed;
@end

@implementation MainSplitViewDelegate

@synthesize accountView;
@synthesize rightView;
@synthesize lastDividerPosition;
@synthesize collapseButton;

- (void)awakeFromNib {
    NSUserDefaults  *sud = [NSUserDefaults standardUserDefaults];
    
//    NSSplitView *mainSplitView = (NSSplitView *) [self.accountView superview];

    self.lastDividerPosition = [sud floatForKey:@"accountSplitWidth"];

//    if([sud boolForKey:@"isAccountCollapsed"]){
    if ([self isAccountCollapsed]) {
//        [mainSplitView setPosition: 0.0 ofDividerAtIndex: 0];
        [self.collapseButton setState: NSOnState];
    }
    else {
//        [mainSplitView setPosition: self.lastDividerPosition ofDividerAtIndex: 0];
        [self.collapseButton setState: NSOffState];
    }

    
    return;
}

- (BOOL) isAccountCollapsed {
    return ([self.accountView frame].size.width < 15.0);
}
//
- (void) saveViewSettingsOn:  (NSUserDefaults *) theUserDefaults {    
    if(![self isAccountCollapsed]){
        self.lastDividerPosition = CGRectGetWidth(NSRectToCGRect([self.accountView bounds]));
    }
    
    [theUserDefaults setFloat: self.lastDividerPosition forKey:@"accountSplitWidth"];
}

- (IBAction)toggleAccountView: sender {
    
    NSSplitView *mainSplitView = (NSSplitView *) [self.accountView superview];

    [mainSplitView layoutSubtreeIfNeeded];
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        
        [context setDuration:1.0];
        // Important, animations don't work without setAllowsImplicitAnimation:
        // also want layer backed view set in IB
        [context setAllowsImplicitAnimation: YES];
        
        if([self isAccountCollapsed]) {
            // Restore split
            [[mainSplitView animator] setPosition: self.lastDividerPosition ofDividerAtIndex: 0];
            //[sender setState: NSOnState];
        }
        else {
            // hide split
            self.lastDividerPosition = CGRectGetWidth(NSRectToCGRect([self.accountView bounds]));
            [[mainSplitView animator] setPosition: 0.0 ofDividerAtIndex: 0];
            //[sender setState: NSOffState];
        }
       
        [mainSplitView layoutSubtreeIfNeeded];
        
    } completionHandler:^{
        
        
    }];
    
}

- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification {
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        
        [context setDuration:1.0];
        // Important, animations don't work without setAllowsImplicitAnimation:
        // also want layer backed view set in IB
        [context setAllowsImplicitAnimation: YES];
        
        if([self isAccountCollapsed]) {
            // Restore split
            [self.collapseButton setState: NSOnState];
        }
        else {
            // hide split
            [self.collapseButton setState: NSOffState];
        }
        
    } completionHandler:^{
        
        
    }];
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {
    return subview == self.accountView;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex {
    
    return subview == self.accountView;
}


@end
