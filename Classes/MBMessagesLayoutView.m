//
//  MBMessagesLayoutView.m
//  MailBoxes
//
//  Created by Taun Chapman on 01/15/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBMessagesLayoutView.h"

@implementation MBMessagesLayoutView

-(void) setPropertyDefaults {
    self.layer.backgroundColor = [[NSColor greenColor] CGColor];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        [self setPropertyDefaults];
    }
    return self;
}

-(void) awakeFromNib {
    [self setPropertyDefaults];
}

-(NSSize) intrinsicContentSize {
    NSSize intrinsicSize;
    NSScrollView* scrollView = [self enclosingScrollView];
    if (scrollView) {
        intrinsicSize = [scrollView contentSize];
    } else {
        intrinsicSize = NSMakeSize(200, 200);
    }
    return intrinsicSize;
}

-(void) updateConstraints {
//    NSScrollView* scrollView = [self enclosingScrollView];
//    if (scrollView) {
//        NSClipView* clipView = [scrollView contentView];
//        [clipView setTranslatesAutoresizingMaskIntoConstraints: NO];
//        NSDictionary *views = NSDictionaryOfVariableBindings(clipView, self);
//        
//        [clipView addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[self]-(<=5)-|"
//                                                                          options:0
//                                                                          metrics:nil
//                                                                            views:views]];
//        
//        [clipView addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[self]-5-|"
//                                                                          options:0
//                                                                          metrics:nil
//                                                                            views:views]];
//    }
    [super updateConstraints];
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
    // Drawing code here.
}

@end
