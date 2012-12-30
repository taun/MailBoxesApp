//
//  MBMessageViewController.m
//  MailBoxes
//
//  Created by Taun Chapman on 10/21/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import "MBMessageViewController.h"
#import "MBMessage+IMAP.h"
#import <QuartzCore/QuartzCore.h>

@implementation MBMessageViewController
@synthesize messageController;
@synthesize message;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // init code
        [[self view] setWantsLayer: YES];
//        [NSAnimationContext beginGrouping];
//        [[NSAnimationContext currentContext] setDuration: 1.0];
//        
//        CABasicAnimation* alphaAnim = [CABasicAnimation animationWithKeyPath: @"alphaValue"];
//        [alphaAnim setFromValue: [NSNumber numberWithFloat: 0.0]];
//        [alphaAnim setToValue: [NSNumber numberWithFloat: 1.0]];
//        NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys: alphaAnim, @"alphaValue", nil];
//        [[self view] setAnimations: dict];
    }
    return self;
}

//-(void) setMessage:(MBMessage *)newMessage {
//    [[self view] setAlphaValue: 0.0];
//    
//    message = newMessage;
//    
////    [[self view] setBounds: startRect];
//    
//
//    
//    
//    
//    
//    CAAnimationGroup* group = [CAAnimationGroup animation];
//    [group setAnimations: [NSArray arrayWithObjects: alphaAnim, sizeAnim, nil]];
//    
//    [[[self view] animator] setAlphaValue: 1.0];
//    [NSAnimationContext endGrouping];
//}

@end
