//
//  MBMessagesCollectionItemView.m
//  MailBoxes
//
//  Created by Taun Chapman on 01/28/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBMessagesCollectionItemView.h"

@implementation MBMessagesCollectionItemView

+ (BOOL) requiresConstraintBasedLayout {
    return YES;
}

/*
 Want our collection item view to be resizable.
 The automask gives a fixed height after the view is laid out.
 */
- (BOOL)translatesAutoresizingMaskIntoConstraints {
    return YES;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void) awakeFromNib {
    NSView* superview = self.superview;
    CGFloat height = 300;
    
    if (superview) {
        [superview addConstraints:@[
                                    [NSLayoutConstraint constraintWithItem: superview
                                                                 attribute:NSLayoutAttributeTop
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self
                                                                 attribute:NSLayoutAttributeTop
                                                                multiplier:1.0
                                                                  constant: 5],
                                    
                                    [NSLayoutConstraint constraintWithItem: superview
                                                                 attribute:NSLayoutAttributeLeft
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self
                                                                 attribute:NSLayoutAttributeLeft
                                                                multiplier:1.0
                                                                  constant: 2],
                                    
                                    [NSLayoutConstraint constraintWithItem: superview
                                                                 attribute:NSLayoutAttributeBottom
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self
                                                                 attribute:NSLayoutAttributeBottom
                                                                multiplier:1.0
                                                                  constant: 10],
                                    
                                    [NSLayoutConstraint constraintWithItem: superview
                                                                 attribute:NSLayoutAttributeWidth
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self
                                                                 attribute:NSLayoutAttributeWidth
                                                                multiplier:1
                                                                  constant: 0],
                                    
                                    [NSLayoutConstraint constraintWithItem: self
                                                                 attribute:NSLayoutAttributeHeight
                                                                 relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                    toItem:nil
                                                                 attribute:NSLayoutAttributeNotAnAttribute
                                                                multiplier:1
                                                                  constant: height],
                                    
                                    ]];
    }

}

- (void) updateConstraints {
    
    // last
    [super updateConstraints];
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
    // Drawing code here.
}

@end
