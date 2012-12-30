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
    return [(NSSplitView *)[self.accountView superview] isSubviewCollapsed: self.accountView];
}

- (void) saveViewSettingsOn:  (NSUserDefaults *) theUserDefaults {
//    [theUserDefaults setBool: self.isAccountCollapsed forKey:@"isAccountCollapsed"];
    
    if(![self isAccountCollapsed]){
        self.lastDividerPosition = CGRectGetWidth(NSRectToCGRect([self.accountView bounds]));
    }
    
    [theUserDefaults setFloat: self.lastDividerPosition forKey:@"accountSplitWidth"];
}

- (IBAction)toggleAccountView: sender {
    NSSplitView *mainSplitView = (NSSplitView *) [self.accountView superview];
    
    if( [mainSplitView isSubviewCollapsed: self.accountView]) {
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
    [mainSplitView adjustSubviews];
}


-(CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
    return 300.0;
}

-(CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
{
    return 200.0;
}

    // This only prevents resizing the topView in cases where the user does not use the divider (resizing the window primarily).
-(BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview
{
    return subview != self.accountView;
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {
    return subview == self.accountView;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex {
    
    return subview == self.accountView;
}


@end
